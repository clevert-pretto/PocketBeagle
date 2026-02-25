# Variables
CC = arm-linux-gnueabihf-gcc
TARGET = blink_led_arm
SRC = blink.c
IP = 192.168.7.2
USER = debian

# The default 'all' rule
all:
	$(CC) $(SRC) -o $(TARGET)

# A rule to transfer the file to the board
deploy: all
	# Create the directory on the board first (-p ensures no error if it exists)
	# ssh $(USER)@$(IP) "mkdir -p ~/PocketBeagle/phase-1-user-space/03-cross-compilation"
	# Now copy the file
	scp $(TARGET) $(USER)@$(IP):~/PocketBeagle/phase-1-user-space/03-cross-compilation/

# A rule to clean up local binaries
clean:
	rm -f $(TARGET)