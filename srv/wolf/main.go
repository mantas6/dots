package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"github.com/gorilla/mux"
)

// Path to dnsmasq leases file
const leasesFilePath = "/var/lib/misc/dnsmasq.leases"

// Function to read the MAC address for a given hostname from dnsmasq leases file
func getMacAddressFromHostname(hostname string) (string, error) {
	file, err := os.Open(leasesFilePath)
	if err != nil {
		return "", fmt.Errorf("failed to open leases file: %v", err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) >= 4 && fields[3] == hostname {
			return fields[1], nil
		}
	}

	if err := scanner.Err(); err != nil {
		return "", fmt.Errorf("error reading leases file: %v", err)
	}

	return "", fmt.Errorf("hostname not found")
}

// Function to read the IP address for a given hostname from dnsmasq leases file
func getIPAddressFromHostname(hostname string) (string, error) {
	file, err := os.Open(leasesFilePath)
	if err != nil {
		return "", fmt.Errorf("failed to open leases file: %v", err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) >= 4 && fields[3] == hostname {
			return fields[2], nil
		}
	}

	if err := scanner.Err(); err != nil {
		return "", fmt.Errorf("error reading leases file: %v", err)
	}

	return "", fmt.Errorf("hostname not found")
}

// Function to handle WOL request
func wolHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	hostname := vars["hostname"]

	macAddress, err := getMacAddressFromHostname(hostname)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	// Execute the wol command with the MAC address
	cmd := exec.Command("wakeonlan", "-i", "192.168.0.255", macAddress)
	err = cmd.Run()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to execute wol command: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Sent WOL packet to MAC address %s", macAddress)
}

// Function to handle IP resolution request
func resolveIPHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	hostname := vars["hostname"]

	ipAddress, err := getIPAddressFromHostname(hostname)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s", ipAddress)
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/wol/{hostname}", wolHandler).Methods("GET")
    r.HandleFunc("/res/{hostname}", resolveIPHandler).Methods("GET")

	fmt.Println("Starting server on :5001")
	if err := http.ListenAndServe(":5001", r); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
