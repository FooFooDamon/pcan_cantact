# ------------------------------------------------
# Generic Makefile (based on gcc)
#
# ChangeLog :
#	2023-06-06 - Man Hung-Coeng: Generate *.dfu file(s)
#	2023-06-04 - Man Hung-Coeng: Support STM32F072x
#	2017-02-10 - Several enhancements + project update mode
#   2015-07-22 - first version
# ------------------------------------------------

######################################
# target
######################################
TARGET = pcan_$(BOARD)_hw
TARGET_VARIANT = $(shell echo $(BOARD) | tr  '[:lower:]' '[:upper:]')
MCU_SERIES ?= F042
ifeq ($(filter F042 F072, $(MCU_SERIES)),)
$(error Alternative value of MCU_SERIES: F042 F072)
endif

#######################################
# paths
#######################################
# Build path
BUILD_DIR = build-$(BOARD)

######################################
# source
######################################
# C sources
USBD_DESC_SRC = Src/usbd_desc-fixup.c
ifeq ($(shell ls $(USBD_DESC_SRC) 2> /dev/null),)
USBD_DESC_SRC = Src/usbd_desc.c
$(warning *** To make an identifiable PCAN driver, you have to modify some contents in $(USBD_DESC_SRC))
endif
C_SOURCES =  \
Src/main.c \
Src/usbd_conf.c \
$(USBD_DESC_SRC) \
Src/pcan_usb.c \
Src/pcan_can.c \
Src/pcan_led.c \
Src/pcan_protocol.c \
Src/pcan_timestamp.c \
Src/system_stm32f0xx.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_ll_usb.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_pcd.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_pcd_ex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_rcc.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_rcc_ex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_gpio.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_cortex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_can.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_core.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ctlreq.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ioreq.c \

# ASM sources
ifeq ($(MCU_SERIES), F042)
ASM_SOURCES =  \
startup_stm32f042x6.s
else
ASM_SOURCES =  \
startup_stm32f072c8tx.s
endif


#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m0

# fpu
# NONE for Cortex-M0/M0+/M3

# float-abi


# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# macros for gcc
# AS defines
AS_DEFS = 

# C defines
ifeq ($(MCU_SERIES), F042)
MCU_SERIES_DEF = -DSTM32F042x6
else
MCU_SERIES_DEF = -DSTM32F072xB
endif
C_DEFS =  \
-DUSE_HAL_DRIVER \
$(MCU_SERIES_DEF) \
-DNDEBUG \
$(BOARD_DEFS)


# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES =  \
-ISrc \
-IDrivers/STM32F0xx_HAL_Driver/Inc \
-IMiddlewares/ST/STM32_USB_Device_Library/Core/Inc \
-IDrivers/CMSIS/Device/ST/STM32F0xx/Include \
-IDrivers/CMSIS/Include


# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fno-common -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -Wpedantic -Wextra -fno-common -fdata-sections -ffunction-sections -std=c99 \
$(BOARD_FLAGS) \
-D$(TARGET_VARIANT)

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# link script
ifeq ($(MCU_SERIES), F042)
LDSCRIPT = STM32F042C6Tx_FLASH.ld
else
LDSCRIPT = STM32F072C8TX_FLASH.ld
endif

# libraries
LIBS = -lc -lm -lnosys 
LIBDIR = 
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

.PHONY : all

# default action: build all
all: cantact_16 cantact_8 entree canable

cantact_16:
	$(MAKE) BOARD=cantact_16 DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=16000000' elf hex bin dfu

cantact_8:
	$(MAKE) BOARD=cantact_8 DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=8000000' elf hex bin dfu

entree:
	$(MAKE) BOARD=entree DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=0' elf hex bin dfu

canable: 
	$(MAKE) BOARD=canable DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=0' elf hex bin dfu

ollie:
	$(MAKE) BOARD=ollie DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=16000000' elf hex bin dfu

#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

ELF_TARGET = $(BUILD_DIR)/$(TARGET).elf
BIN_TARGET = $(BUILD_DIR)/$(TARGET).bin
DFU_TARGET = $(BUILD_DIR)/$(TARGET).dfu
HEX_TARGET = $(BUILD_DIR)/$(TARGET).hex

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@

$(BUILD_DIR)/%.dfu: $(BUILD_DIR)/%.bin | $(BUILD_DIR)
	cp $< $@ && dfu-suffix --add $@
	
$(BUILD_DIR):
	mkdir $@

dfu: $(DFU_TARGET)

bin: $(BIN_TARGET)

elf: $(ELF_TARGET)

hex: $(HEX_TARGET)

#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)*

clean_obj:
	-rm -f $(BUILD_DIR)*/*.o $(BUILD_DIR)*/*.d $(BUILD_DIR)*/*.lst

#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
