/**
 * demo.c
 * 
 * Linux C program to perform MMIO read/write to an FPGA PCIe BAR 
 * using /dev/mem and mmap().
 * 
 * HOW TO USE:
 * 1. Find the physical address of the FPGA PCIe BAR:
 *    Run: `lspci -v`
 *    Look for your device (e.g., Class FF00, as configured in the TCL script).
 *    Note the address of Memory at <ADDRESS> (e.g., d0000000).
 * 
 * 2. Compile:
 *    `make` (for real hardware) or `make mock` (for local simulation)
 * 
 * 3. Run:
 *    Standard: `sudo ./demo <PHYS_ADDR_HEX> <OFFSET_HEX> [VALUE_HEX]`
 *    Mock:     `./demo_mock <ADDR_HEX> <OFFSET_HEX> [VALUE_HEX]`
 * 
 * Example:
 *    Read:  `sudo ./demo 0xd0000000 0x0`
 *    Write: `sudo ./demo 0xd0000000 0x0 0xDEADBEEF`
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#define MAP_SIZE 4096UL
#define MAP_MASK (MAP_SIZE - 1)

int main(int argc, char **argv) {
    if (argc < 3) {
        printf("Usage: %s <phys_addr> <offset> [value]\n", argv[0]);
        return 1;
    }

    /* Parse arguments */
    off_t target_phys_addr = strtoul(argv[1], NULL, 0);
    off_t offset = strtoul(argv[2], NULL, 0);
    int do_write = (argc >= 4);
    uint32_t write_val = do_write ? (uint32_t)strtoul(argv[3], NULL, 0) : 0;

    void *map_base, *virt_addr;

#ifdef MOCK_MODE
    printf("--- MOCK MODE: Simulation using malloc() instead of /dev/mem ---\n");
    map_base = malloc(MAP_SIZE);
    if (!map_base) {
        perror("malloc failed");
        return 1;
    }
    memset(map_base, 0, MAP_SIZE);
    /* For mock mode, we ignore the physical address and just use the offset */
    virt_addr = map_base + (offset & MAP_MASK);
#else
    int fd;
    /* Open /dev/mem (requires root) */
    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        fprintf(stderr, "Error: Could not open /dev/mem (%s). Are you root?\n", strerror(errno));
        return 1;
    }

    /* 
     * Map the physical memory of the BAR into our process address space.
     * Note: We must map on a page-aligned boundary.
     */
    map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, target_phys_addr & ~MAP_MASK);
    if (map_base == MAP_FAILED) {
        fprintf(stderr, "Error: mmap failed (%s)\n", strerror(errno));
        close(fd);
        return 1;
    }

    /* Calculate the virtual address with the offset */
    virt_addr = map_base + (target_phys_addr & MAP_MASK) + offset;
#endif

    if (do_write) {
        /* MMIO Write */
        printf("Writing 0x%08X to virtual address %p (Offset: 0x%lx)\n", 
               write_val, virt_addr, (unsigned long)offset);
        *((volatile uint32_t *) virt_addr) = write_val;
    } else {
        /* MMIO Read */
        uint32_t read_val = *((volatile uint32_t *) virt_addr);
        printf("Read 0x%08X from virtual address %p (Offset: 0x%lx)\n", 
               read_val, virt_addr, (unsigned long)offset);
    }

    /* Clean up */
#ifdef MOCK_MODE
    free(map_base);
#else
    if (munmap(map_base, MAP_SIZE) == -1) {
        fprintf(stderr, "Error: munmap failed (%s)\n", strerror(errno));
    }
    close(fd);
#endif

    return 0;
}
