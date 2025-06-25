#ifndef INFO_H
#define INFO_H

// System information functions
char* get_os_name();
char* get_os_info();
char* get_kernel_info();
char* get_cpu_detailed_info(); 
char* get_memory_info();
char* get_gpu_info();
char* get_uptime_info();
char* get_storage_info();
char* get_serial_number();
char* get_hostname();

#endif // INFO_H