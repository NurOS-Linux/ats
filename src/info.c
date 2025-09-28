#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/statvfs.h>

#ifdef HAVE_LIBCPUID
#include <libcpuid/libcpuid.h>
#endif

#define MAX_LINE_LENGTH 1024
#define MAX_INFO_LENGTH 512

// Function to read a file and return its content
static char* read_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        return NULL;
    }
    
    // For /proc files, we can't use fseek/ftell, so read line by line
    char* content = NULL;
    size_t total_size = 0;
    size_t buffer_size = 1024;
    char line[1024];
    
    content = malloc(buffer_size);
    if (!content) {
        fclose(file);
        return NULL;
    }
    content[0] = '\0';
    
    while (fgets(line, sizeof(line), file)) {
        size_t line_len = strlen(line);
        
        // Expand buffer if needed
        if (total_size + line_len + 1 >= buffer_size) {
            buffer_size *= 2;
            char* new_content = realloc(content, buffer_size);
            if (!new_content) {
                free(content);
                fclose(file);
                return NULL;
            }
            content = new_content;
        }
        
        strcat(content, line);
        total_size += line_len;
    }
    
    fclose(file);
    return content;
}

// Function to execute command and return output
static char* execute_command(const char* command) {
    FILE* pipe = popen(command, "r");
    if (!pipe) return NULL;
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) {
        pclose(pipe);
        return NULL;
    }
    
    if (fgets(result, MAX_INFO_LENGTH, pipe) != NULL) {
        // Remove newline
        char* newline = strchr(result, '\n');
        if (newline) *newline = '\0';
    } else {
        strcpy(result, "Unknown");
    }
    
    pclose(pipe);
    return result;
}

// Function to find value after key in text
static char* find_value_after_key(const char* text, const char* key) {
    char* line = strstr(text, key);
    if (!line) return NULL;
    
    char* colon = strchr(line, '=');
    if (!colon) {
        colon = strchr(line, ':');
        if (!colon) return NULL;
    }
    
    colon++; // Skip the = or :
    while (*colon == ' ' || *colon == '\t' || *colon == '"') colon++;
    
    char* end = strchr(colon, '\n');
    if (!end) end = colon + strlen(colon);
    
    // Remove trailing quotes and whitespace
    while (end > colon && (*(end-1) == '"' || *(end-1) == ' ' || *(end-1) == '\t' || *(end-1) == '\r')) {
        end--;
    }
    
    int length = end - colon;
    char* result = malloc(length + 1);
    if (!result) return NULL;
    
    strncpy(result, colon, length);
    result[length] = '\0';
    
    return result;
}

char* get_os_name() {
    char* os_release = read_file("/etc/os-release");
    if (!os_release) return strdup("unknown");
    
    char* id = find_value_after_key(os_release, "ID=");
    free(os_release);
    
    if (!id) return strdup("unknown");
    return id;
}

char* get_os_info() {
    char* os_release = read_file("/etc/os-release");
    if (!os_release) return strdup("Unknown Operating System");
    
    char* pretty_name = find_value_after_key(os_release, "PRETTY_NAME=");
    if (pretty_name) {
        free(os_release);
        return pretty_name;
    }
    
    char* name = find_value_after_key(os_release, "NAME=");
    char* version = find_value_after_key(os_release, "VERSION=");
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) {
        free(os_release);
        if (name) free(name);
        if (version) free(version);
        return strdup("Unknown Operating System");
    }
    
    if (name && version) {
        snprintf(result, MAX_INFO_LENGTH, "%s %s", name, version);
    } else if (name) {
        strncpy(result, name, MAX_INFO_LENGTH - 1);
        result[MAX_INFO_LENGTH - 1] = '\0';
    } else {
        strcpy(result, "Unknown Operating System");
    }
    
    free(os_release);
    if (name) free(name);
    if (version) free(version);
    
    return result;
}

char* get_kernel_info() {
    struct utsname uts;
    if (uname(&uts) != 0) {
        return strdup("Unknown");
    }
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) return strdup("Unknown");
    
    snprintf(result, MAX_INFO_LENGTH, "%s %s", uts.sysname, uts.release);
    return result;
}

char* get_cpu_detailed_info() {
#ifdef HAVE_LIBCPUID
    // Try libcpuid first for better information
    if (cpuid_present()) {
        struct cpu_raw_data_t raw;
        struct cpu_id_t data;
        
        if (cpuid_get_raw_data(&raw) >= 0 && cpu_identify(&raw, &data) >= 0) {
            char* result = malloc(MAX_INFO_LENGTH);
            if (!result) return strdup("Unknown Processor");
            
            // Build detailed CPU info from libcpuid
            strcpy(result, data.brand_str);
            
            if (data.num_cores > 0) {
                if (data.num_logical_cpus > data.num_cores) {
                    snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                            " (%d cores, %d threads)", data.num_cores, data.num_logical_cpus);
                } else {
                    snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                            " (%d cores)", data.num_cores);
                }
            }
            
            // Add frequency info if available
            int freq_mhz = cpu_clock_measure(100, 1);
            if (freq_mhz > 0) {
                if (freq_mhz >= 1000) {
                    snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                            " @ %.2f GHz", freq_mhz / 1000.0);
                } else {
                    snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                            " @ %d MHz", freq_mhz);
                }
            }
            
            // Add cache info
            if (data.l3_cache > 0) {
                snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                        ", %d KB L3 cache", data.l3_cache);
            } else if (data.l2_cache > 0) {
                snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                        ", %d KB L2 cache", data.l2_cache);
            }
            
            // Add vendor info if not Intel/AMD
            if (data.vendor != VENDOR_INTEL && data.vendor != VENDOR_AMD) {
                const char* vendor_str = NULL;
                switch (data.vendor) {
                    case VENDOR_AMD:
                        vendor_str = "AMD";
                        break;
                    case VENDOR_INTEL:
                        vendor_str = "Intel";
                        break;
                    case VENDOR_CYRIX:
                        vendor_str = "Cyrix";
                        break;
                    case VENDOR_NEXGEN:
                        vendor_str = "NexGen";
                        break;
                    case VENDOR_TRANSMETA:
                        vendor_str = "Transmeta";
                        break;
                    case VENDOR_UMC:
                        vendor_str = "UMC";
                        break;
                    case VENDOR_CENTAUR:
                        vendor_str = "Centaur";
                        break;
                    case VENDOR_RISE:
                        vendor_str = "Rise";
                        break;
                    case VENDOR_SIS:
                        vendor_str = "SiS";
                        break;
                    case VENDOR_NSC:
                        vendor_str = "NSC";
                        break;
                    default:
                        vendor_str = "Unknown";
                        break;
                }
                
                if (vendor_str && strlen(vendor_str) > 0) {
                    snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result),
                            " (%s)", vendor_str);
                }
            }
            
            return result;
        }
    }
#endif
    
    // Fallback to /proc/cpuinfo parsing
    char* cpuinfo = read_file("/proc/cpuinfo");
    if (!cpuinfo) return strdup("Unknown Processor");
    
    char* cpu_name = NULL;
    char* cpu_vendor = NULL;
    char* cpu_cache = NULL;
    double cpu_freq = 0.0;
    int cores = 0;
    int threads = 0;
    
    // Make a copy for strtok since it modifies the string
    char* cpuinfo_copy = malloc(strlen(cpuinfo) + 1);
    strcpy(cpuinfo_copy, cpuinfo);
    
    char* line = strtok(cpuinfo_copy, "\n");
    while (line) {
        if (strstr(line, "model name") && !cpu_name) {
            cpu_name = find_value_after_key(line, "model name");
            if (cpu_name) {
                // Clean up CPU name
                char* tmp = cpu_name;
                char* clean = malloc(strlen(tmp) + 1);
                char* dest = clean;
                
                while (*tmp) {
                    if (strncmp(tmp, "(R)", 3) == 0) {
                        tmp += 3;
                    } else if (strncmp(tmp, "(TM)", 4) == 0) {
                        tmp += 4;
                    } else if (strncmp(tmp, "CPU", 3) == 0 && (tmp[3] == ' ' || tmp[3] == '\0')) {
                        tmp += 3;
                        while (*tmp == ' ') tmp++;
                    } else {
                        *dest++ = *tmp++;
                    }
                }
                *dest = '\0';
                
                // Remove double spaces
                char* final = malloc(strlen(clean) + 1);
                char* src = clean;
                dest = final;
                int prev_space = 0;
                
                while (*src) {
                    if (*src == ' ') {
                        if (!prev_space) {
                            *dest++ = *src;
                            prev_space = 1;
                        }
                    } else {
                        *dest++ = *src;
                        prev_space = 0;
                    }
                    src++;
                }
                *dest = '\0';
                
                free(cpu_name);
                free(clean);
                cpu_name = final;
            }
        } else if (strstr(line, "vendor_id") && !cpu_vendor) {
            cpu_vendor = find_value_after_key(line, "vendor_id");
        } else if (strstr(line, "cache size") && !cpu_cache) {
            cpu_cache = find_value_after_key(line, "cache size");
        } else if (strstr(line, "cpu MHz") && cpu_freq == 0.0) {
            char* freq_str = find_value_after_key(line, "cpu MHz");
            if (freq_str) {
                cpu_freq = atof(freq_str);
                free(freq_str);
            }
        } else if (strstr(line, "processor")) {
            threads++;
        } else if (strstr(line, "cpu cores")) {
            char* cores_str = find_value_after_key(line, "cpu cores");
            if (cores_str) {
                cores = atoi(cores_str);
                free(cores_str);
            }
        }
        line = strtok(NULL, "\n");
    }
    
    free(cpuinfo);
    free(cpuinfo_copy);
    
    if (!cpu_name) {
        cpu_name = strdup("Unknown Processor");
    }
    
    if (cores == 0) cores = threads; // Fallback
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) {
        if (cpu_name) free(cpu_name);
        if (cpu_vendor) free(cpu_vendor);
        if (cpu_cache) free(cpu_cache);
        return strdup("Unknown Processor");
    }
    
    // Build detailed info
    strcpy(result, cpu_name);
    
    if (cores > 0) {
        if (threads > cores) {
            snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                    " (%d cores, %d threads)", cores, threads);
        } else {
            snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                    " (%d cores)", cores);
        }
    }
    
    if (cpu_freq > 0) {
        if (cpu_freq >= 1000) {
            snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                    " @ %.2f GHz", cpu_freq / 1000.0);
        } else {
            snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                    " @ %.0f MHz", cpu_freq);
        }
    }
    
    if (cpu_cache) {
        snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                ", %s cache", cpu_cache);
        free(cpu_cache);
    }
    
    if (cpu_vendor && strcmp(cpu_vendor, "GenuineIntel") != 0 && 
        strcmp(cpu_vendor, "AuthenticAMD") != 0) {
        snprintf(result + strlen(result), MAX_INFO_LENGTH - strlen(result), 
                " (%s)", cpu_vendor);
    }
    
    // Cleanup
    if (cpu_name) free(cpu_name);
    if (cpu_vendor) free(cpu_vendor);
    
    return result;
}

char* get_memory_info() {
    char* meminfo = read_file("/proc/meminfo");
    if (!meminfo) {
        return strdup("Unknown");
    }
    
    long total_kb = 0, available_kb = 0, buffers_kb = 0, cached_kb = 0, free_kb = 0;
    
    // Make a copy for strtok since it modifies the string
    char* meminfo_copy = malloc(strlen(meminfo) + 1);
    strcpy(meminfo_copy, meminfo);
    
    char* line = strtok(meminfo_copy, "\n");
    while (line) {
        if (strstr(line, "MemTotal:")) {
            sscanf(line, "MemTotal: %ld kB", &total_kb);
        } else if (strstr(line, "MemAvailable:")) {
            sscanf(line, "MemAvailable: %ld kB", &available_kb);
        } else if (strstr(line, "MemFree:")) {
            sscanf(line, "MemFree: %ld kB", &free_kb);
        } else if (strstr(line, "Buffers:")) {
            sscanf(line, "Buffers: %ld kB", &buffers_kb);
        } else if (strstr(line, "Cached:")) {
            sscanf(line, "Cached: %ld kB", &cached_kb);
        }
        line = strtok(NULL, "\n");
    }
    
    free(meminfo);
    free(meminfo_copy);
    
    if (total_kb == 0) {
        return strdup("Unknown");
    }
    
    // Calculate used memory
    long used_kb;
    if (available_kb > 0) {
        used_kb = total_kb - available_kb;
    } else {
        // Fallback: used = total - free - buffers - cached
        used_kb = total_kb - free_kb - buffers_kb - cached_kb;
    }
    
    if (used_kb < 0) used_kb = 0;
    
    // Convert to bytes for formatting
    long long total_bytes = (long long)total_kb * 1024;
    long long used_bytes = (long long)used_kb * 1024;
    
    // Calculate usage percentage
    double usage_percent = (double)used_bytes / (double)total_bytes * 100.0;
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) return strdup("Unknown");
    
    // Format: "Used / Total (XX%)"
    char used_str[64], total_str[64];
    
    // Format used memory
    if (used_bytes >= 1024LL * 1024 * 1024) {
        snprintf(used_str, sizeof(used_str), "%.1f GB", (double)used_bytes / (1024.0 * 1024 * 1024));
    } else {
        snprintf(used_str, sizeof(used_str), "%.0f MB", (double)used_bytes / (1024.0 * 1024));
    }
    
    // Format total memory
    if (total_bytes >= 1024LL * 1024 * 1024) {
        snprintf(total_str, sizeof(total_str), "%.1f GB", (double)total_bytes / (1024.0 * 1024 * 1024));
    } else {
        snprintf(total_str, sizeof(total_str), "%.0f MB", (double)total_bytes / (1024.0 * 1024));
    }
    
    snprintf(result, MAX_INFO_LENGTH, "%s / %s (%.0f%%)", used_str, total_str, usage_percent);
    
    return result;
}

char* get_gpu_info() {
    char* output = execute_command("lspci | grep -i 'vga\\|3d\\|display'");
    if (!output) return strdup("Unknown Graphics");
    
    // Find the part after the colon
    char* colon = strchr(output, ':');
    if (!colon) {
        free(output);
        return strdup("Unknown Graphics");
    }
    
    colon += 2; // Skip ": "
    
    // Clean up GPU name
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) {
        free(output);
        return strdup("Unknown Graphics");
    }
    
    strncpy(result, colon, MAX_INFO_LENGTH - 1);
    result[MAX_INFO_LENGTH - 1] = '\0';
    
    // Remove "Corporation" and clean up
    char* corp = strstr(result, "Corporation");
    if (corp) {
        memmove(corp, corp + 11, strlen(corp + 11) + 1);
    }
    
    // Remove double spaces
    char* src = result;
    char* dest = result;
    int prev_space = 0;
    
    while (*src) {
        if (*src == ' ') {
            if (!prev_space) {
                *dest++ = *src;
                prev_space = 1;
            }
        } else {
            *dest++ = *src;
            prev_space = 0;
        }
        src++;
    }
    *dest = '\0';
    
    // Trim trailing space
    int len = strlen(result);
    while (len > 0 && result[len - 1] == ' ') {
        result[--len] = '\0';
    }
    
    free(output);
    return result;
}

char* get_uptime_info() {
    char* uptime_str = read_file("/proc/uptime");
    if (!uptime_str) {
        return strdup("Unknown");
    }
    
    double uptime_seconds;
    if (sscanf(uptime_str, "%lf", &uptime_seconds) != 1) {
        free(uptime_str);
        return strdup("Unknown");
    }
    
    free(uptime_str);
    
    int days = (int)(uptime_seconds / 86400);
    int hours = (int)((uptime_seconds - days * 86400) / 3600);
    int minutes = (int)((uptime_seconds - days * 86400 - hours * 3600) / 60);
    
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) return strdup("Unknown");
    
    if (days > 0) {
        snprintf(result, MAX_INFO_LENGTH, "%d day%s, %d hour%s", 
                days, days != 1 ? "s" : "", 
                hours, hours != 1 ? "s" : "");
    } else if (hours > 0) {
        snprintf(result, MAX_INFO_LENGTH, "%d hour%s, %d minute%s", 
                hours, hours != 1 ? "s" : "", 
                minutes, minutes != 1 ? "s" : "");
    } else {
        snprintf(result, MAX_INFO_LENGTH, "%d minute%s", 
                minutes, minutes != 1 ? "s" : "");
    }
    
    return result;
}

char* get_storage_info() {
    char* output = execute_command("df -h / | tail -1");
    if (!output) return strdup("Unknown");
    
    // Parse df output: filesystem, size, used, available, use%, mount
    char filesystem[256], size[32], used[32], available[32], use_percent[16], mount[256];
    
    int parsed = sscanf(output, "%255s %31s %31s %31s %15s %255s", 
                       filesystem, size, used, available, use_percent, mount);
    
    free(output);
    
    if (parsed >= 4) {
        char* result = malloc(MAX_INFO_LENGTH);
        if (!result) return strdup("Unknown");
        
        snprintf(result, MAX_INFO_LENGTH, "%s available of %s", available, size);
        return result;
    }
    
    return strdup("Unknown");
}

char* get_serial_number() {
    // Try multiple methods without sudo
    
    // Method 1: DMI table (works without sudo on some systems)
    char* output = execute_command("dmidecode -s system-serial-number 2>/dev/null");
    if (output && strcmp(output, "To Be Filled By O.E.M.") != 0 && 
        strcmp(output, "Not Specified") != 0 && strcmp(output, "") != 0) {
        return output;
    }
    if (output) free(output);
    
    // Method 2: Try /sys/class/dmi/id/product_serial
    char* sys_serial = read_file("/sys/class/dmi/id/product_serial");
    if (sys_serial) {
        // Remove newline
        char* newline = strchr(sys_serial, '\n');
        if (newline) *newline = '\0';
        
        if (strcmp(sys_serial, "To Be Filled By O.E.M.") != 0 && 
            strcmp(sys_serial, "Not Specified") != 0 && strcmp(sys_serial, "") != 0) {
            return sys_serial;
        }
        free(sys_serial);
    }
    
    // Method 3: Try /proc/cpuinfo for some ARM devices
    char* cpuinfo = read_file("/proc/cpuinfo");
    if (cpuinfo) {
        char* serial_line = strstr(cpuinfo, "Serial");
        if (serial_line) {
            char* serial = find_value_after_key(serial_line, "Serial");
            free(cpuinfo);
            if (serial && strcmp(serial, "") != 0) {
                return serial;
            }
            if (serial) free(serial);
        }
        free(cpuinfo);
    }
    
    return strdup("Unknown");
}

char* get_hostname() {
    char hostname[256];
    if (gethostname(hostname, sizeof(hostname)) == 0) {
        return strdup(hostname);
    }
    return strdup("Unknown");
}

char* get_display_info() {
    char* output = execute_command("xrandr --listmonitors | tail -n +2");
    if (!output) return strdup("Unknown Display");

    // Cut the trash
    char* result = malloc(MAX_INFO_LENGTH);
    if (!result) {
        free(output);
        return strdup("Unknown Display");
    }

    strncpy(result, output, MAX_INFO_LENGTH - 1);
    result[MAX_INFO_LENGTH - 1] = '\0';

    free(output);
    return result;
}
