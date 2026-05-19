To clone the repo
git clone <url>

To make the changes into staging
git add . or <filename>

To check the status of staging or not
git status

Output:
If it was modified then the output will be
 On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   docker-cleanup.sh
        modified:   rocky.sh

To commit
git commit -m "The message for better understandability"

To push to the branch
git push origin main

To change branch
git checkout <branch name>

To create a new branch
git checkout -b <branch name>

To delete a branch
git branch -d <branch name>

To make from stage from unstage
git restore --staged <file name>

To undo the changes 
git restore <file name>


