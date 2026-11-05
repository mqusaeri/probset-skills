Bikin dua flag acak di sini sebelum build:

    python3 -c "import secrets; print('flag{' + secrets.token_hex(12) + '}')" > flags/user.txt
    python3 -c "import secrets; print('flag{' + secrets.token_hex(12) + '}')" > flags/root.txt

Probset mode: ganti `flag` dengan flag_prefix klien.
