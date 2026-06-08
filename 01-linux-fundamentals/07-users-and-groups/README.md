# 07 · Users & Groups

> Maps to **Linux Fundamentals → Section 14: Users & Groups**
> (`sudo`, `useradd -m`, `passwd`, `su`, sudoers, `groupadd`, `groupdel`, `gpasswd`, `adduser`)

This is sysadmin work - the heart of operating a real server. Onboarding
engineers, creating team groups, granting (and revoking) privileges. It's the most
"DevOps engineer" section in the whole course.

> 🐧 **This only works in the container.** Creating users, editing groups and
> using real `sudo` are impossible on a Mac host (macOS has no `useradd`). Here you
> have passwordless `sudo` - you're effectively the box's administrator.

## How to use this set

```bash
# from the linux-fundamentals/ folder
make build                          # once (rebuilds with adduser available)
make start  S=07-users-and-groups
make verify S=07-users-and-groups
make reset  S=07-users-and-groups
```

---

## Tier 1 - sudo & a new user

**1.1 (graded)** Some places only root can write. Use `sudo` to create the directory
`/opt/acme`.

**1.2 (graded)** Create a user `alice` **with a home directory**. *(Hint: `useradd`
needs a flag to make the home dir; set her password too with `passwd` - interactive,
not graded.)*

## Tier 2 - Groups & privileges *(hint: `groupadd`, `gpasswd`, `adduser`)*

**2.1 (graded)** Create a team group called `developers`.

**2.2 (graded)** Add `alice` to the `developers` group.

**2.3 (graded)** Grant `alice` administrative rights by putting her in the `sudo`
group. *(Check membership any time with `id -nG alice` or `cat /etc/group`.)*

## Tier 3 - Challenge: onboard a team, then offboard *(goal only)*

> **Scenario:** two engineers join, you stand up the `ops` team group, then one
> person leaves and you have to revoke their access cleanly.

**3.1 (graded)** Onboard two new users `bob` and `carol` (each with a home dir),
create a group `ops`, and put all three (`alice`, `bob`, `carol`) in it.

**3.2 (graded)** Carol leaves. Remove her from `ops` **but keep her account** -
`bob` and `alice` stay in the group.

**3.3 (graded)** The old `legacy` group is unused - delete it.

All green = you've run a full access lifecycle: create → grant → revoke → clean up.

---

## Self-check questions

1. What does `sudo` actually do, and why isn't everyone allowed to use it?
2. Why the `-m` flag on `useradd`?
3. How do you give a user admin rights without making them root?
4. Difference between `gpasswd -a`, `gpasswd -d` and `gpasswd -M`?
