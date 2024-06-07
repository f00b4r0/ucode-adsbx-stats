#!/usr/bin/env ucode
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Thibaut Varène <hacks@slashdirt.org>

'use strict';

import { open, popen, readfile, writefile } from 'fs';

const REMOTE_URL = "https://adsbexchange.com/api/receive/";
const JSON_FILE = "/run/adsbexchange-feed/aircraft.json";
const UUID_FILE = "/usr/local/share/adsbexchange/adsbx-uuid";
const WAIT_TIME = 5;	// 5s

function floor(f)
{
	let i = int(f);	// int() truncates
	if ((i != f) && (i < 0))
		i--;
	return i;
}

// grab UUID || die
const uuid = trim(readfile(UUID_FILE));
if (!uuid)
	die("Couldn't read UUID!");

// enter loop
while (true) {
	let data = {};

	sleep(WAIT_TIME * 1000);

	let aircraft = open(JSON_FILE, 'r');
	try {
		data = json(aircraft);
		aircraft.close();
	} catch (e) {
		warn("Warning: failed to parse JSON\n");
		sleep(100);	// add some time offset in case we're racing the writer
		continue;
	}

	if (!data) {
		warn("Warning: no data!\n");
		continue;
	}

	// add "uuid" member with content of UUID_FILE
	data.uuid = uuid;
	// add "v" member empty string (don't care)
	data.v = "";

	let nac = length(data.aircraft);
	if (!nac)
		continue;	// we're not reporting anything is there's nothing to report

	let rssi = 0, rssi_min = 0, rssi_max = -1000;
	for (let ac in data.aircraft) {
		rssi += ac.rssi;
		rssi_min = min(ac.rssi, rssi_min);
		rssi_max = max(ac.rssi, rssi_max);
	}

	rssi /= nac;
	data.rssi = floor(rssi);
	data["rssi-min"] = floor(rssi_min);
	data["rssi-max"] = floor(rssi_max);
	
	// stringify data
	data = sprintf("%J", data);

	// SSL POST to REMOTE_URL with headers "adsbx-uuid: $UUID" and "Content_Encoding: gzip"
	try {
		// try zlib module
		const zlib = require('zlib');
		let gzip = zlib.deflate(data, true, zlib.Z_BEST_SPEED);
		try {
			// try WIP curl module
			const curl = require('curl');
			let headers = [ `adsbx-uuid: ${uuid}`, "Content_Encoding: gzip" ];
			curl.post(REMOTE_URL, gzip, headers);		
		} catch (e) {
			// fallback to curl executable
			let post = popen(`curl -m 10 -s -X POST -H "adsbx-uuid: ${uuid}" -H "Content_Encoding: gzip" --data-binary @- ${REMOTE_URL}`, 'w');
			post.write(gzip);
			post.close();
		}
	} catch (e) {
		// fallback to gzip | curl executables
		let post = popen(`gzip --fast -c | curl -m 10 -s -X POST -H "adsbx-uuid: ${uuid}" -H "Content_Encoding: gzip" --data-binary @- ${REMOTE_URL}`, 'w');
		post.write(data);
		post.close();
	}
}
