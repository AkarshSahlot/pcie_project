# Makefile for pcie-p4 demo software

CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = demo
SRC = demo.c

.PHONY: all mock clean

all: $(TARGET)

# Standard build (requires root to run)
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

# Mock build (can run without root for local testing)
mock: $(SRC)
	$(CC) $(CFLAGS) -DMOCK_MODE $(SRC) -o $(TARGET)_mock

clean:
	rm -f $(TARGET) $(TARGET)_mock
