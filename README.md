# DiCA: A Hardware-Software Co-Design for Differential Check-Pointing in Intermittently Powered Devices

Intermittently powered devices rely on opportunistic energy-harvesting to function, leading to recurrent power interruptions. Therefore, check-pointing techniques are crucial for reliable device operation. Current strategies involve storing snapshots of the device's state at specific intervals or upon events. Time-based check-pointing takes check-points at regular intervals, providing a basic level of fault tolerance. However, frequent check-point generation can lead to excessive/unnecessary energy consumption. Event-based check-pointing, on the other hand, captures the device's state only upon specific trigger events or conditions. While the latter reduces energy usage, accurately detecting trigger events and determining optimal triggers can be challenging. Finally, differential check-pointing selectively stores state changes made since the last check-point, reducing storage and energy requirements for the check-point generation. However, current differential check-pointing strategies rely on software instrumentation, introducing challenges related to the precise tracking of modifications in volatile memory as well as added energy consumption (due to instrumentation overhead).

This paper introduces DiCA, a proposal for a hardware/software co-design to create differential check-points in intermittent devices. DiCA leverages an affordable hardware module that simplifies the check-pointing process, reducing the check-point generation time and energy consumption. This hardware module continuously monitors volatile memory, efficiently tracking modifications and determining optimal check-point times. To minimize energy waste, the module dynamically estimates the energy required to create and store the check-point based on tracked memory modifications, triggering the check-pointing routine optimally via a non-maskable interrupt. Experimental results show the cost-effectiveness and energy efficiency of DiCA, enabling extended application activity cycles in intermittently powered embedded devices

## Paper

[Our paper](./dica.pdf) for DiCA was accepted to ICCAD '23