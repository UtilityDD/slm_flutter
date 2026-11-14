"""Re-encode a freshly synthesised speech MP3 to the app's voice standard (set 2026-11-04):
MP3 CBR 32 kbps, mono, 24 kHz, +0.4 dB (cancels LAME's level drop). Edge TTS saves 48 kbps,
which made every re-record grow the APK again (480 clips, -4.4 MB when re-encoded on 2026-11-14).

usage (library):  from tool.voice_32k import to_32k; to_32k(path)
usage (CLI):      python tool/voice_32k.py <file-or-folder> [...]   # speech folders only (learn_voice, voice, guide_voice)

Uses `ffmpeg` on PATH, else imageio_ffmpeg's bundled binary. If neither exists it prints a warning and
leaves the file as it is (the app still plays it; it is only bigger).
"""
import os
import shutil
import subprocess
import sys
import tempfile


def _ffmpeg():
    exe = shutil.which('ffmpeg')
    if exe:
        return exe
    try:
        import imageio_ffmpeg  # already used by the media tools
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return None


def _bitrate_kbps(ffmpeg, path):
    # The AUDIO STREAM's bitrate ("Audio: mp3 ..., 32 kb/s"), not the container's "bitrate:", which
    # reads high on short clips because of header overhead (re-encoding those again only loses quality).
    r = subprocess.run([ffmpeg, '-hide_banner', '-i', path], capture_output=True, text=True)
    for line in r.stderr.splitlines():
        if 'Audio:' in line and 'kb/s' in line:
            try:
                return int(line.split('kb/s')[0].split(',')[-1].strip())
            except ValueError:
                pass
    return None


def to_32k(path, quiet=True):
    """Re-encode `path` in place when it is above 32 kbps. Returns True if it changed the file."""
    if not path.lower().endswith('.mp3') or not os.path.isfile(path):
        return False
    ffmpeg = _ffmpeg()
    if not ffmpeg:
        print(f'[voice_32k] no ffmpeg found; left {os.path.basename(path)} as saved', file=sys.stderr)
        return False
    kbps = _bitrate_kbps(ffmpeg, path)
    if kbps is not None and kbps <= 32:
        return False
    fd, tmp = tempfile.mkstemp(suffix='.mp3', dir=os.path.dirname(path) or '.')
    os.close(fd)
    try:
        subprocess.run([ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-i', path,
                        '-ac', '1', '-ar', '24000', '-af', 'volume=0.4dB',
                        '-c:a', 'libmp3lame', '-b:a', '32k', '-map_metadata', '-1', tmp], check=True)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)
    if not quiet:
        print(f'[voice_32k] {os.path.basename(path)}: {kbps} -> 32 kbps')
    return True


SPEECH_DIRS = ('learn_voice', 'voice', 'guide_voice')


if __name__ == '__main__':
    n = 0
    for arg in sys.argv[1:]:
        files = [os.path.join(d, f) for d, _, fs in os.walk(arg) for f in fs] if os.path.isdir(arg) else [arg]
        for f in files:
            if not any(f'/{d}/' in f.replace(os.sep, '/') for d in SPEECH_DIRS):
                continue  # music and effects keep their own encoding
            n += to_32k(f, quiet=False)
    print(f'{n} file(s) re-encoded')
