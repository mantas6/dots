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

const leasesFilePath = "/var/lib/misc/dnsmasq.leases"

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
	path := strings.TrimPrefix(r.URL.Path, "/wol/")
	if path == "" || strings.Contains(path, "/") {
		http.Error(w, "Invalid hostname", http.StatusBadRequest)
		return
	}
	hostname := path

	macAddress, err := getMacAddressFromHostname(hostname)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	cmd := exec.Command("wakeonlan", "-i", "192.168.0.255", macAddress)
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

	fmt.Println("Starting server on :5001")
	if err := http.ListenAndServe(":5001", mux); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
