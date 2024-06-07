# ucode-adsbx-stats

A lightweight ucode-based replacement for https://github.com/ADSBexchange/adsbexchange-stats

Rationale: much lower (~90% less) CPU usage.

## License

MIT License

Copyright: (C) 2024 Thibaut VARÈNE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Dependencies

 - [ucode](https://github.com/jow-/ucode/)
 - ucode-mod-zlib **or** gzip
 - ucode-mod-curl **or** curl
 
## Usage

Simply run the script in the background as user "adsbexchange", e.g.:

```sh
sudo su adsbexchange -s /bin/sh -c 'nice -19 ./adsbx-stats.uc &'
```

## Notes

Compared to the Bash original, this script cuts a few corners:

 - Only one path is searched for JSON files (easy to improve if needed);
 - No creation of UUID file is attempted: if UUID is missing, the script will
   not start.
 - No local copy of JSON file is performed (unnecessary: VFS guarantees
   read/writes to be atomic, if the data is incomplete we simply discard it and
   retry. No need to be pedantic here as missed uploads will only affect local
   map refresh rate);
 - No DNS caching is performed (this is a job for the host or local DNS resolver);
 - Age of JSON file is not checked: if it's too old, it will be discarded by
   remote server anyway.
 - Loop interval is *approximately* 5s: ucode does not allow fine-grained
   intervals (at least not without using uloop - not available on !OpenWrt, and
   here again, it doesn't matter: this will only introduce some jitter in local
   map refresh rate);
 - Finally no data is sent when there is no aircraft records. This does not
   affect the feeder uptime stats.

All these tweaks contribute to making the tool much faster, much less CPU heavy,
light on memory usage, and thus much more suitable for underpowered systems
(e.g. Raspberry Pi Zero).

