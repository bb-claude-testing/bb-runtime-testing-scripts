# 🛡️ The Security Playground — Explained Like You're 10

Hi! 👋 This folder is the **instruction book** for a pretend computer playground
where we play a game of **"bad guy vs. security camera."**

- We build a little toy computer city (called a **Kubernetes cluster**).
- We let a pretend **bad guy** try sneaky, naughty things inside it.
- We have a super-smart **security camera** called **Sysdig** watching everything.
- Then we check: *did the camera catch the bad guy doing each naughty thing?* 🎥

Nothing here is real or dangerous. It's all a **safe practice playground** so the
grown-ups who protect real computers can make sure their cameras work. Think of it
like a fire drill — we *practice* the scary stuff when it's safe, so we're ready
if it ever happens for real.

---

## 🧩 The big pieces

| Thing | What it is (kid version) |
|-------|--------------------------|
| **Kubernetes cluster** | A toy city made of lots of tiny computers called **pods**. |
| **Pod** | One little house in the city where a program lives. |
| **Bastion** | A safe control room with a keyboard. We type commands here to play. |
| **Sysdig** | The security camera + alarm system watching the whole city. |
| **A "detection"** | The camera going *"BEEP! I saw something naughty!"* |

When the camera beeps, the grown-ups see a message in Sysdig that says exactly
*what* naughty thing happened and *where*. Our whole game is about making those
beeps happen on purpose.

---

## 📁 What's in this repo

There are two main toy boxes (folders):

### 1. `scripts/` — the buttons we press
These are little command files (they end in `.sh`). When you run one, it makes
something happen in the city. Two kinds live here:

- **The numbered workshop steps** (`01-…`, `02-…`, `06-…`, `07-…`) — the guided
  tour of the playground (explained lower down).
- **The `sysevent/` box** — a big bag of **33 "naughty thing" tests** (the new
  ones!) plus a helper called `run.sh` to press them easily.

### 2. `k8s-manifests/` — the blueprints for the city
These are the building plans. They tell the toy city *what houses to build* —
the playground apps, a pretend database, and now the **sysevent robot** that
knows how to do all 33 naughty tricks on command.

---

## 🤖 The new toy: the **sysevent robot**

We added a special robot to the city. It's a pod that already knows how to do
**33 different naughty tricks** (like a magician with 33 tricks up its sleeve).
It comes from a ready-made box called `marcelsysdig/sysevent:2.0.0`.

The robot starts **asleep** 😴 (we set `pauseonstart: "true"`), so it never does
anything by surprise. *You* wake it up and tell it which trick to do. That way
**you** decide exactly when each camera-beep happens.

### ▶️ How to make the robot do a trick (from the bastion)

In the control room (the bastion), there's a helper button: **`run.sh`** (it lives
in `scripts/sysevent/`, and the bastion copies it to `~/sysevent/run.sh`).

```bash
cd ~/sysevent

./run.sh list                          # 1) see the list of all 33 tricks
./run.sh reverse_shell_detected_python  # 2) do ONE trick
./run.sh all                           # 3) do every quick trick (skips the 2 long ones)
./run.sh chains                        # 4) do the 2 big multi-step adventures
./run.sh everything                    # 5) do absolutely everything
```

After you press a trick, go look in **Sysdig → Threats/Events** and filter to
`kubernetes.namespace.name = "sysevent"`. You should see the camera's beeps! 🎉

> 🧠 **Why do the tricks sometimes show an error?** That's normal! The robot only
> needs to *try* the naughty thing for the camera to notice. It's like the camera
> catching you *reaching* for the cookie jar — it doesn't matter if you actually
> got a cookie. `run.sh` keeps going even when a trick "fails."

You can also peek at the robot's little web page (it has one) through the
LoadBalancer address — ask Sysdig/your kubectl for the `sysevent` service's
public hostname.

---

## 🎭 The 33 naughty tricks — every single one explained

For each trick: **what it pretends to do** 🎬, and **why a real bad guy would do
it** 😈. The camera is built to beep on every one.

### 🐚 Sneaking in & remote control
- **`reverse_shell_detected_sh.sh`** — Opens a secret walkie-talkie back to the bad
  guy so they can type commands into our computer from far away. 😈 This is how
  hackers "live inside" a computer they broke into.
- **`reverse_shell_detected_python.sh`** — Same secret walkie-talkie, but built with
  the Python tool instead. (Different tool, same naughty goal.)
- **`netcat_remote_code_execution_in_container.sh`** — Tricks a website into running
  the bad guy's commands, then opens that same far-away walkie-talkie. 😈 Sneaking
  in through a website's front door.

### 🔑 Stealing secrets & keys
- **`read_sensitive_file_untrusted.sh`** — Peeks at `/etc/shadow`, the file that
  holds everyone's secret passwords. 😈 Steal passwords = pretend to be someone else.
- **`read_k8s_service_account_token_from_terminal.sh`** — Steals the city's special
  "all-access badge" (a Kubernetes token). 😈 With the badge you can open lots of doors.
- **`find_private_keys_or_passwords.sh`** — Hunts around for secret keys (`id_rsa`).
  😈 Keys let you unlock other computers without a password.
- **`find_azure_credentials.sh`** — Hunts for the secret login to a cloud account
  (`azure.json`). 😈 Cloud logins can control a whole company's computers.
- **`gpg_key_reconnaissance.sh`** — Looks for special "secret message" keys (GPG).
  😈 Steal these and you can read someone's locked-up secret messages.
- **`dump_memory_for_credentials.sh`** — Reads the computer's "short-term memory"
  hoping a password is sitting there. 😈 Sometimes secrets get left lying around.
- **`contact_EC2_instance_metadata_service_from_container.sh`** — Asks a hidden
  cloud helpline (`169.254.169.254`) for the computer's cloud passwords. 😈 A classic
  way to steal cloud keys from inside a hacked app.

### 🕵️ Snooping around (reconnaissance)
- **`reconnaissance_attempt_to_find_SUID_binaries.sh`** — Looks for special programs
  that run with extra power. 😈 Bad guys use these to become "the boss" (root).
- **`detect_reconnaissance_scripts_executing_LinEnum.sh`** — Downloads and runs a
  famous "snoop everywhere" tool called LinEnum. 😈 It makes a giant list of weak spots.

### 🪤 Setting up traps & hiding (persistence + sneakiness)
- **`create_symlink_over_sensitive_files.sh`** — Makes a sneaky shortcut that points
  at the secret password file. 😈 A trick to grab files you shouldn't touch.
- **`create_hardlink_over_sensitive_files.sh`** — Almost the same sneaky-shortcut
  trick, but a different kind of link.
- **`log_file_symlink_to_null.sh`** — Points the "diary" (log file) into a magic
  trash can so nothing gets written down. 😈 No diary = no proof the bad guy was here.
- **`modify_ld_so_preload.sh`** — Edits a special list so the bad guy's program
  secretly runs *every* time. 😈 A way to hide and stay forever.
- **`modify_binary_dirs.sh`** — Sneaks a new program into the "official programs"
  drawer. 😈 Hides bad tools where they look normal.
- **`diamorphine_rootkit_activity.sh`** — Pokes a famous invisibility-cloak program
  (a "rootkit") with a secret signal. 😈 Rootkits make bad stuff totally invisible.

### 🧹 Covering tracks & turning off the alarm
- **`tampering_with_security_software_in_container.sh`** — Tries to switch off the
  computer's safety helper. 😈 Turn off the alarm before robbing the house.
- **`remove_bulk_data_from_disk.sh`** — Shreds the history list so no one can see
  what commands were typed. 😈 Erasing footprints.
- **`kill_known_malicious_process.sh`** — Stops a *different* bad program. 😈 Bad guys
  kick out *other* bad guys so they're the only one in charge.

### 💸 Making money & stealing data (crypto-mining + exfiltration)
- **`detect_crypto_miners_using_the_stratum_protocol.sh`** — Starts a "coin-digging"
  program that steals your computer's power to make digital money. 😈 Free money for
  the bad guy, slow computer for you.
- **`malicious_ips_or_domains_detected_on_command_line.sh`** — Talks to a known
  bad-guy website. 😈 Phoning home to the villain's headquarters.
- **`dns_lookup_for_offensive_security_tool_omain_detected.sh`** — Looks up a website
  that hacker tools use to sneak data out. 😈 A secret tunnel for stolen stuff.
- **`network_relay_binary_exfiltration_activities_detected.sh`** — Uses a network tool
  to *ship stolen files out* of the computer. 😈 Mailing your secrets to the bad guy.

### 🦠 Bad programs & tricks
- **`malware_detection.sh`** — Runs a *pretend* virus called EICAR. (It's a famous
  totally-safe fake virus everyone uses to test alarms.) 😈 Stand-in for real malware.
- **`code_compiler_downloaded_and_launched_in_container.sh`** — Uses a "program-builder"
  (`gcc`) to build a tool right inside the app. 😈 Building weapons on the spot.
- **`base64-encoded_shell_script_execution.sh`** — Runs a command that was written in
  secret code (base64) to hide it. 😈 Disguising naughty commands so they're hard to read.
- **`base64-encoded_python_script_execution.sh`** — Same secret-code trick, using Python.

### 🎬 The two big adventures (multi-step chains)
These do **many** tricks in a row, like a whole movie of an attack:
- **`simulated_attack_chain.sh`** — A **7-step** story: sneak in → look around → steal
  secrets → set a trap → hide → phone home → mail out the loot.
- **`k8s_cluster_takeover_and_cryptominer.sh`** — A **10-step** story where the bad guy
  takes over the *whole toy city* and starts a coin-digging machine. The grand finale! 🎆

### 🗄️ The `archive/` box (older tricks, kept for reference)
- **`archive/read_shell_configuration_file.sh`** — A non-shell program peeks at the
  computer's start-up settings file. 😈 Learning how the computer is set up.
- **`archive/webserver_writing_to_non-allowed_directory.sh`** — Tricks a website into
  writing a sneaky file where it shouldn't. 😈 Planting a hidden back door in a website.

---

## 🎓 The numbered workshop steps (the guided tour)

These are the older, guided parts of the playground. The grown-up leading the
workshop runs them in order:

- **`01-01-example-curls.sh`** … **`01-04-…`** — *Module 1.* Pokes the
  "security-playground" app to make it do naughty things, with different camera
  settings each time (normal, locked-down, drift-off, malware-off) so you can see
  how the rules change what gets caught.
- **`02-01-example-curls-bucket-public.sh`** + `02-cfg-…irsa.yaml` — *Module 2.*
  Tricks the app into using a too-powerful cloud badge and poking cloud storage.
- **`06-01-example-curls-networkpolicy.sh`** — *Module 6.* Tests the city's "who's
  allowed to talk to whom" rules (network policy).
- **`07-01-example-curls-log4shell.sh`** + **`07-02-…spring4shell.sh`** — *Module 7.*
  Attacks a deliberately-broken Java app using two super-famous real-world bugs
  (Log4Shell and Spring4Shell).
- **`llmjacking/`** — extra scripts about misusing AI/LLM services.

### 🔧 Helper scripts (tools, not attacks)
- **`refresh-security-playgrounds.sh`** — Resets the playground apps to a fresh start.
- **`set-up-irsa.sh`** — Sets up the special cloud badge used in Module 2.
- **`install-cli-amd-linux.sh`** — Installs a needed command-line tool.
- **`test-all-workshop-commands.sh`** — Runs through everything to check it all works.
- **`generated-network-policy*.yml`** — Auto-made "who can talk to whom" rules.
- **`scripts/sysevent/run.sh`** — ⭐ the new helper that fires the 33 tricks (see above).

---

## 🏗️ The city blueprints (`k8s-manifests/`)

These build the toy city. They're numbered in the order they're built:

- **`01`–`05`** — the main **security-playground** app (the bad guy's favorite toy).
- **`06`–`11`** — locked-down versions (`restricted`, `restricted-nodrift`) to show
  how stronger rules behave.
- **`12`–`17`** — a tiny **hello** server + clients (used for network tests).
- **`18`–`19`** — a pretend **database** (postgres-sakila).
- **`20`–`22`** — a "no-malware-rule" version of the playground.
- **`23`–`25`** — ⭐ the new **sysevent robot**: its namespace, its pod, and its
  web-page door (LoadBalancer).
- **`kustomization.yaml`** — the master list that says "build all of these."

---

## ✅ The whole game in one sentence

**We build a safe toy computer city, let a friendly robot do 33 naughty tricks on
command, and check that our security camera (Sysdig) beeps for every single one —
so we know it'll catch real bad guys too.** 🛡️🎥

> ⚠️ **Grown-up note:** every script here performs deliberate attack-simulation
> behavior. Only ever run them inside the disposable workshop cluster — never on a
> real machine or a network you don't own.
