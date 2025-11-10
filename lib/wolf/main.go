package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

const leasesFilePath = "/var/lib/dnsmasq/dnsmasq.leases"
const subnetAddress = "10.0.1.255"
const listenAddress = ":5001"

func getMacAddressFromHostname(hostname string) (string, error) {
	file, err := os.Open(leasesFilePath)
	if err != nil {
		return "", fmt.Errorf("Failed to open leases file: %v", err)
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
		return "", fmt.Errorf("Error reading leases file: %v", err)
	}

	return "", fmt.Errorf("Hostname not found")
}

func wolHandler(w http.ResponseWriter, r *http.Request) {
	hostname := strings.TrimPrefix(r.URL.Path, "/wol/")
	if hostname == "" || strings.Contains(hostname, "/") {
		http.Error(w, "Invalid hostname", http.StatusBadRequest)
		return
	}

	macAddress, err := getMacAddressFromHostname(hostname)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	cmd := exec.Command("wakeonlan", "-i", subnetAddress, macAddress)
	err = cmd.Run()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to execute command: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Sent WOL packet to MAC address %s", macAddress)
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/wol/", wolHandler)

	fmt.Println("Starting server on " + listenAddress)
	if err := http.ListenAndServe(listenAddress, mux); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
