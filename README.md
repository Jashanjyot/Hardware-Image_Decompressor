# Hardware Image Decompressor

This project focuses on the efficient decompression of a **320x240 image** using a hardware platform based on the **Altera DE2 board**. The implementation utilizes **SystemVerilog** and involves a set of carefully designed finite state machines. The goal is to enhance hardware design proficiency by strategically implementing various components, including shift registers, multipliers, adders, dual-port RAMs, and intricate state machine structures, with a focus on leveraging symmetry for reduced clock cycles.

## Key Features

- **Altera DE2 Board:** The project is implemented and tested on the **Altera DE2 board**, serving as the hardware platform for the decompression process.

- **Finite State Machines:** A set of finite state machines is designed to efficiently decompress compressed data corresponding to a **320x240-pixel image**.

- **Hardware Components:** The project strategically employs shift registers, multipliers, adders, dual-port RAMs, and intricate state machine structures to achieve optimized decompression. Symmetry is leveraged to reduce clock cycles and enhance overall efficiency.

- **UART Interface:** Compressed data for the **320x240-pixel image** is processed via a **UART interface**, facilitating communication between the system and the **Altera DE2-115 board**.

- **External SRAM:** The compressed image data is received and stored in an **external SRAM** for efficient processing.

- **Verilog Program:** A Verilog program, utilizing **Quartus II**, is written to configure the FPGA on the **Altera DE2 board**. This program enables the FPGA to read and recover the compressed image data, sending it to a VGA controller for display on a monitor.

## Project Workflow

1. **Data Reception:**
   Compressed data for the **320x240-pixel image** is received via the **UART interface**.

2. **Storage:**
   The received compressed image data is stored in an **external SRAM** for efficient processing.

3. **Decompression:**
   Finite state machines and hardware components are utilized to decompress the image data.

4. **FPGA Configuration:**
   A Verilog program written in **Quartus II** configures the FPGA on the **Altera DE2 board**.

5. **VGA Display:**
   The recovered image data is sent to a VGA controller for display on a monitor.

## **Dependencies**

- Altera DE2 Board
- Quartus II
- SystemVerilog
- UART Interface
- External SRAM
- VGA Controller
   
## Acknowledgments

This project combines hardware and software to develop a Hardware Image Decompressor on an Altera DE2 board. The system efficiently processes compressed data for a 320 x 240-pixel image, using a Verilog program to configure the FPGA for image recovery and display. Finite state machines in SystemVerilog optimize decompression, leveraging various components for efficiency. Refer to the project report for specific details on the components used.


