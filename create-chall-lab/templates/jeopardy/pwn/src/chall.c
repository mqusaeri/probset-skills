/* Template soal pwn. Ganti dengan program fiktif soal kamu.
 * Satu kelemahan yang dimaksud, satu jalan ke flag. Flag dibaca dari file saat runtime.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define FLAG_PATH "/home/ctf/flag.txt"

static void setup(void) {
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    alarm(60); /* koneksi nggak boleh nyangkut selamanya */
}

/* Panggil cuma dari jalur solve yang dimaksud. */
static void print_flag(void) {
    char buf[128] = {0};
    FILE *f = fopen(FLAG_PATH, "r");
    if (!f) { puts("flag hilang, kabari fasilitator"); exit(1); }
    fgets(buf, sizeof buf, f);
    fclose(f);
    printf("%s\n", buf);
}

int main(void) {
    char name[64];
    setup();
    puts("=== Layanan Fiktif ===");
    printf("Nama: ");
    if (!fgets(name, sizeof name, stdin)) return 0;
    name[strcspn(name, "\n")] = 0;
    printf("Halo, %s\n", name);
    /* GANTI_INI: logika soal dan kelemahan yang dimaksud. */
    (void)print_flag;
    return 0;
}
