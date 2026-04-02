# Access a Xen Virtual Machine via VNC

This guide explains how to establish a VNC connection to a Xen VM. This is necessary for any HVM-based VM, which includes Windows VMs and any Linux VM installed via ISO. Since HVM guests have no paravirtual console, VNC is the only way to access them during and after installation.

---

## The Approach

Rather than binding VNC to `0.0.0.0` (which exposes the port to the entire local network), VNC is configured to listen on `127.0.0.1` only, the Xen host's loopback interface. Access from a client machine is then done via an SSH tunnel, which is encrypted and requires normal SSH authentication. No VNC password needed, no open port on the network.

---

## Update the Xen VM Config

Add the following line to your VM's Xen config file alongside the existing CPU, memory, and disk settings:

```python
vfb = [ 'type=vnc,vnclisten=127.0.0.1,vncunused=1,vncdisplay=1' ]
```

- `vnclisten=127.0.0.1` binds VNC to loopback only, not accessible from the network
- `vncunused=1` automatically picks the next free port starting from 5900, so multiple VMs can each get their own VNC port without conflicts
- `vncdisplay=1` sets the base display number (port 5901); adjust per VM to keep them distinct

Any HVM VM, Windows or Linux, must be fully shut down and restarted via Xen for the new config to take effect. A reboot from within the guest OS is not sufficient; Xen only reads the updated config on a fresh `xl create`.

```bash
xl shutdown myvm
xl create /etc/xen/myvm.cfg
```

---

## Verify VNC is Listening

After the VM starts, confirm the VNC port is active on the Xen host:

**On Linux (dom0):**

```bash
ss -tulpn
```

Expected output, you should see one entry per running VM with VNC enabled:

```
Netid   State    Recv-Q  Send-Q  Local Address:Port   Peer Address:Port
tcp     LISTEN   0       1       127.0.0.1:5900       0.0.0.0:*
tcp     LISTEN   0       1       127.0.0.1:5901       0.0.0.0:*
tcp     LISTEN   0       1       127.0.0.1:5902       0.0.0.0:*
```

Each port corresponds to one VM. The `vncunused=1` option ensures that if 5900 is taken, Xen will automatically assign 5901, 5902, and so on.

---

## Open an SSH Tunnel

From your local client machine, forward the VNC port over SSH:

**On Linux/macOS/Windows:**

```bash
ssh -fNL 5900:127.0.0.1:5900 user@hostname
```

Flag breakdown:

| Flag | Meaning                                              |
| ---- | ---------------------------------------------------- |
| `-f` | Send SSH to the background before executing          |
| `-N` | Don't execute a remote command, port forwarding only |
| `-L` | Forward a local port over the SSH connection         |

The format `5900:127.0.0.1:5900` means: bind local port 5900, and forward it to `127.0.0.1:5900`. The VNC traffic never leaves the SSH session unencrypted.

To confirm the tunnel is active on your local machine:

**Linux/macOS:**

```bash
ss -tulpn
```

**Windows:**

```
netstat -ao
```

You should see something like:

```
Netid   State    Recv-Q  Send-Q  Local Address:Port   Peer Address:Port   Process
tcp     LISTEN   0       128     127.0.0.1:5900       0.0.0.0:*           ssh (pid=3226)
```

---

## Connect with a VNC Client

Point your VNC viewer at `127.0.0.1:5900` (or `localhost:5900`). The connection goes through the SSH tunnel to the Xen host and directly into the VM's console.

Any standard VNC client works: RealVNC, TigerVNC, Remmina, or the built-in VNC viewer on macOS.

---

## Close the Tunnel When Done

Always close the SSH tunnel after finishing your work.

**Linux/macOS:**

```bash
pkill -f "ssh -.*L"
```

**Windows (find the PID first with `netstat -ao`, then):**

```
taskkill /pid 17712
```

Closing the tunnel ensures the local port is freed and no lingering forwarding session remains open.

---

## Port Assignment Reference

When running multiple VMs, keep a simple mapping of which VM uses which VNC port to avoid confusion:

| VM     | vncdisplay | VNC Port |
| ------ | ---------- | -------- |
| myvm-1 | 0          | 5900     |
| myvm-2 | 1          | 5901     |
| myvm-3 | 2          | 5902     |

Set `vncdisplay` explicitly in each VM's config rather than relying solely on `vncunused=1,` it makes the mapping predictable and reproducible across restarts.