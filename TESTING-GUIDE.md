# Rice Farm Agriculture Visualization — Testing & Troubleshooting Guide

## A. Connecting the app to your Liquid Galaxy

1. Ensure your tablet/phone is on the SAME network as the LG rig.
2. Find the master's IP: on the LG master machine, run:
       ifconfig | grep "inet "
   (use the LAN address, e.g. 192.168.x.x)
3. Open the app → Settings (gear icon) and enter:
   - IP Address: the master IP from step 2
   - SSH Port: 22
   - Username: lg
   - Password: your rig's lg password
   - Number of Screens: your rig's screen count (e.g. 3 or 5)
4. Tap "Connect to LG". A green "Connected to Liquid Galaxy" bar
   confirms success.
5. ON CONNECT THE APP AUTOMATICALLY: cleans all previous KML state,
   sets folder permissions, and displays the project logo. Connection
   takes ~5 seconds. This is expected.

## B. Quick health check (do this first, takes 1 minute)

Open a terminal / SSH into the master:
    ssh lg@<MASTER_IP>

Then run:
    cat /var/www/html/kmls.txt
    ls -la /var/www/html/kml/
    curl -s -o /dev/null -w "%{http_code}\n" http://lg1:81/kml/logo.png

Expected right after connect: kmls.txt is EMPTY, kml/ contains
logo.png + slave_*.kml files, and curl prints 200.

## C. If COLORED KMLs don't appear

The app has a built-in diagnostic. If a RED BANNER appears at the
top of a feature screen, photograph it and send it to us — it names
the exact failing stage:

| Banner says            | Meaning                        | Likely fix |
|------------------------|--------------------------------|------------|
| [1/3] kmls.txt empty   | write to master failed         | Reconnect app; check SSH stability |
| [2/3] HTTP 403         | Apache can't read the file     | Run section F fix 1 |
| [2/3] HTTP 404         | file missing                   | Reconnect and retry |
| [2/3] HTTP 000         | port 81 unreachable            | Run section F fix 2 |
| [3/3] slave cannot download | lg1 not resolvable on slave | Run section F fix 3 |

If NO banner appears but NO colors show either (delivery is healthy,
rendering is failing), run on the master:

    cat /var/www/html/kmls.txt
    curl -s -o /dev/null -w "%{http_code}\n" "$(head -1 /var/www/html/kmls.txt)"
    head -25 /var/www/html/kml/rice_viz.kml

Send us all three outputs, then try:
1. Home screen → Relaunch (restarts Google Earth on all screens)
2. Wait 40 seconds, reconnect the app, tap "Show all" again

## D. If the LOGO shows a RED CROSS (left screen)

The slave screen cannot download the logo image. On the master:

    ls -la /var/www/html/kml/logo.png
    curl -s -o /dev/null -w "%{http_code}\n" http://lg1:81/kml/logo.png
    sshpass -p <PASSWORD> ssh lg2 "curl -s -o /dev/null -w '%{http_code}\n' http://lg1:81/kml/logo.png"

- File missing → tap Home → Show Logo to re-upload
- curl not 200 on master → section F fix 2
- 200 on master but not on slave → section F fix 3

## E. If the STATS DASHBOARD shows a RED CROSS (right screen)

Same cause as D, different file. On the master:

    ls -la /var/www/html/kml/dashboard.png
    curl -s -o /dev/null -w "%{http_code}\n" http://lg1:81/kml/dashboard.png

Then re-trigger any feature (e.g. tap a state) to re-upload the
dashboard, and re-check.

## F. Common fixes

FIX 1 — permissions:
    echo <PASSWORD> | sudo -S chmod 777 /var/www/html/kml
    echo <PASSWORD> | sudo -S chmod 644 /var/www/html/kml/*.png

FIX 2 — Apache on port 81 not serving:
    curl -s -o /dev/null -w "%{http_code}\n" http://localhost:81/
    sudo service apache2 restart

FIX 3 — slave cannot resolve lg1:
    ssh lg2 "ping -c 1 lg1"
    ssh lg2 "cat /etc/hosts | grep lg1"
    If no lg1 entry exists in the slave's /etc/hosts, the rig
    installation is non-standard — send us this output.

## G. Complete diagnostic dump (if nothing above resolves it)

Run all of these on the master and send us the full output:

    echo "=== kmls.txt ==="; cat /var/www/html/kmls.txt
    echo "=== kml folder ==="; ls -la /var/www/html/kml/
    echo "=== master curl ==="; curl -s -o /dev/null -w "%{http_code}\n" "$(head -1 /var/www/html/kmls.txt)"
    echo "=== KML head ==="; head -25 /var/www/html/kml/rice_viz.kml
    echo "=== logo curl ==="; curl -s -o /dev/null -w "%{http_code}\n" http://lg1:81/kml/logo.png
    echo "=== slave reach ==="; sshpass -p <PASSWORD> ssh -o ConnectTimeout=4 lg2 "curl -s -o /dev/null -w '%{http_code}\n' http://lg1:81/kml/rice_viz.kml"
    echo "=== GE version ==="; cat /opt/google/earth/pro/product_info.txt 2>/dev/null
    echo "=== hosts ==="; cat /etc/hosts