#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#define LED_COUNT 4

const char *LED_PATHS[] = {
    "/sys/class/leds/beaglebone:green:usr0/brightness",
    "/sys/class/leds/beaglebone:green:usr1/brightness",
    "/sys/class/leds/beaglebone:green:usr2/brightness",
    "/sys/class/leds/beaglebone:green:usr3/brightness"
};

int main() {
    int fds[LED_COUNT];
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 50000000L; // 50ms - adjust this for speed!

    // Step 1: Open all file descriptors
    for (int i = 0; i < LED_COUNT; i++) {
        fds[i] = open(LED_PATHS[i], O_WRONLY);
        if (fds[i] < 0) {
            perror("Failed to open LED");
            return 1;
        }
    }

    printf("Starting C-powered Rolling LEDs. Press Ctrl+C to stop.\n");

    while (1) {
        // Forward: 0, 1, 2, 3
        for (int i = 0; i < LED_COUNT; i++) {
            write(fds[i], "1", 1);
            nanosleep(&ts, NULL);
            write(fds[i], "0", 1);
        }

        // Backward: 2, 1 (Skip 3 and 0 to avoid double-blink at ends)
        for (int i = LED_COUNT - 2; i > 0; i--) {
            write(fds[i], "1", 1);
            nanosleep(&ts, NULL);
            write(fds[i], "0", 1);
        }
    }

    // This part is never reached, but good practice:
    for (int i = 0; i < LED_COUNT; i++) close(fds[i]);
    return 0;
}