"""Reject 64-bit ELF libraries with sub-16-KiB LOAD alignment.

Android guidance: https://developer.android.com/guide/practices/page-sizes
The 16-KiB requirement applies to arm64-v8a and x86_64, not 32-bit ABIs."""
import struct
import sys
import zipfile


def load_alignments(data):
    if data[:4] != b'\x7fELF' or data[4] not in (1, 2):
        raise ValueError('Invalid ELF file')
    endian = '<' if data[5] == 1 else '>'
    is_64 = data[4] == 2
    offset = struct.unpack_from(endian + ('Q' if is_64 else 'I'), data, 32 if is_64 else 28)[0]
    size, count = struct.unpack_from(endian + 'HH', data, 54 if is_64 else 42)
    for index in range(count):
        header = offset + index * size
        kind = struct.unpack_from(endian + 'I', data, header)[0]
        if kind == 1:
            yield struct.unpack_from(endian + ('Q' if is_64 else 'I'), data, header + (48 if is_64 else 28))[0]


def check_bundle(path):
    failures = []
    with zipfile.ZipFile(path) as bundle:
        libraries = [
            name for name in bundle.namelist()
            if name.endswith('.so')
            and any(f'/lib/{abi}/' in name for abi in ('arm64-v8a', 'x86_64'))
        ]
        if not libraries:
            raise ValueError('No 64-bit native libraries found in bundle')
        for name in libraries:
            alignments = list(load_alignments(bundle.read(name)))
            if not alignments or any(value < 16384 for value in alignments):
                failures.append(f'{name}: LOAD alignments {alignments}')
        print(f'Checked {len(libraries)} 64-bit ELF libraries for 16-KiB LOAD alignment')
    if failures:
        raise ValueError('\n'.join(failures))


if __name__ == '__main__':
    check_bundle(sys.argv[1])
