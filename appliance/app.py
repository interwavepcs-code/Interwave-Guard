#!/usr/bin/env python3
from flask import Flask, request, redirect, jsonify
import os
import subprocess

app = Flask(__name__)

SETUP_DONE = "/etc/interwave/setup_complete"

def run(cmd):
    subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

@app.route("/")
def root():
    if os.path.exists(SETUP_DONE):
        return redirect("/status")
    return redirect("/setup")

@app.route("/setup", methods=["GET", "POST"])
def setup():
    if request.method == "POST":
        password = request.form.get("password")
        if password:
            run(f"pihole -a -p {password}")
        os.makedirs("/etc/interwave", exist_ok=True)
        open(SETUP_DONE, "w").close()
        return redirect("/status")

    return """
    <h1>Interwave Guard Setup</h1>
    <form method="post">
      <p>Create admin password:</p>
      <input type="password" name="password" required>
      <br><br>
      <button type="submit">Finish Setup</button>
    </form>
    """

@app.route("/status")
def status():
    def ok(cmd):
        return subprocess.call(cmd, shell=True,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0

    return jsonify({
        "setup_complete": os.path.exists(SETUP_DONE),
        "pihole_running": ok("systemctl is-active pihole-FTL"),
        "unbound_running": ok("systemctl is-active unbound"),
        "dns_ok": ok("dig +short google.com @127.0.0.1"),
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
