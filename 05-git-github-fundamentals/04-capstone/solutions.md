# Solutions - Capstone: Zero to Pushed

```bash
cd ~/sandbox/myapp

# 1 - init + first commit
git init
echo "# My App" > README.md
git add README.md
git commit -m "Initial commit"

# 2 - second commit
echo "console.log('hi')" > app.js
git add app.js
git commit -m "Add app.js"

# 3 - link the remote
git remote add origin ~/sandbox/origin.git

# 4 - push
git push -u origin main
```

Then type `check` in the sandbox (or `exit` and let the Academy check it) - expect 4/4.

### The real-world version
The only difference on a real project is step 3: instead of a local path you'd use
your GitHub repo's URL, e.g. `git remote add origin git@github.com:you/myapp.git`.
Everything else is identical - this *is* the workflow.
