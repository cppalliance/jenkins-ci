
## Design Notes

It may be interesting to discuss some of the architectural ideas and design decisions about the docs previews.

Each pull request is given its own URL, such as

https://212.http-proto.prtest.cppalliance.org/http/index.html

Notice the format of the URL. The pull request number is 212. The repository is http-proto. The remainder is the top level domain name of the web server where it is hosted.

master and develop branch docs similarly use a URL scheme https://develop.http-proto.cpp.al

Each pull request has a dedicated URL and hyperlink, and it's own folder in an S3 bucket. An nginx web server hosts the front-end, retrieving the pages from the backend S3 storage.  

## Comparison to github pages

Github pages is convenient for hosting an instance (one copy) of the documentation of a repository. If building the docs for https://github.com/cppalliance/http, then the `master` branch could be added to github pages.  

However, what about hosting separate copies of `master`, `develop`, and each separate pull request `212`, `211`, `210`, `209` , etc.  

Where would all of those be placed in github pages?

Could they each be at the "root" top level of their own domain, as it's done in the current scheme? 

Where would github pages go to retrieve the content that it needs in order to display the docs? You would not want to bloat the size of the git repository, by creating 100's of new git branches, with very many MBs of temporary content, and then when someone runs `git clone` they must always download many copies of doc previews.    

The next issue is permissions and access. Each boostorg repository has specific administrators and maintainers. The CPPAlliance is not an admin of all boost repos, and does not have access to modify setting or github pages on each repo. From the perspective of security, it would be problematic to allow a CPPAlliance bot full read/write access to many boost repositories, in order to write new branches. In comparison, the current Jenkins doc previews do not require any permissions at all, the jobs simply remotely poll the public github repos.

Next, consider "automation". At the present time, a boost developer may request doc previews, by chatting in Slack or opening a PR with a request. Granted, the setup of Jenkins is partially manually. However what usually happens, in more than 50% of cases, is there is some quirky unusual problem with a repository's docs, often library dependencies, or unusual build steps, which require human intervention. There are multiple types of docs: antora, quickbook, etc. A typical situation involves building a new library "capy" or "http-proto", which have unexpected dependencies on each other, and which use a build system that was only recently invented. Exceptions are the rule. There is always something "new". So there are two obstacles to full automation: 1. Development work, to further increase automation which is already to a certain extent present, and 2. The fact that customization is usually needed.

In summary, the architecture and design of the system in purposefully using nginx+S3+remote-polling because it's secure, manageable, maintainable in-house, and doesn't require any permissions or github access to other boost repos. Nginx and S3 are more powerful and more customizable than the limited hosting option of github pages. There are no restrictions about what features may be used with these tools.  In terms of "automation": the system is already scripted to a great extent. It is certainly imaginable to continue in that direction, and find more ways to automate.

The system as it is, evolved over months and years, it is not simple. Any given developer...  is only 1 person, who has a lot to do. There are genuinely really problems with attempting to implement this feature set on github pages, as discussed in this document. You could do something much much simpler, like help a repo publish their master branch on github pages.

### Central managed repository

Another idea: it was suggested that a GitHub Pages implementation could store all doc previews from all target repos within one centrally managed repository. This would solve permissions issues on the separate distributed repos.

Google: github recommended maximum size of repository  

Search results show: "5 GB. While GitHub recommends keeping repositories under 5 GB, there are defined storage limits based on your plan: GitHub Free and Pro accounts have a 2 GB limit per repository, GitHub Team has a 4 GB limit, and GitHub Enterprise Cloud has a 5 GB limit."

As of early 2026 the S3 bucket hosting previews contains 50GB. Planning for the future that means 100GB. If the doc previews were more widely rolled out to all boostorg repos, then 100GB becomes 300GB if you plan for similar storage consumption and increased usage over time. While 300GB is nothing on S3, it's 60 times larger than the recommended max repo size on GitHub. That is clearly a significant problem. 

### Separate repo github pages

Returning back to the idea of hosting previews on each separate individual target repo, where they could at least host their own `master` branch previews... Even in that case it's really suboptimal when compared to hosting such previews on cloud storage (S3). If there are dozens of previews over the course of time, it slowly but surely bloats the size of the repo, adding 100's of MB if enough previews are run. Commits are not easily removed from a git repo in the same way that files can be deleted from an standard directory. Git stores files indefinitely, and doesn't permit deletion. So each repo that hosted previews will be permanently much larger, slower to download, etc.
