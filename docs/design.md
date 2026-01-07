
## Design Notes

It may be interesting to discuss some of the architectural ideas and design decisions about the docs previews.

Each pull request is given its own URL, such as

https://212.http-proto.prtest.cppalliance.org/http_proto/index.html

Notice the format of the URL. The pull request number is 212. The repository is http-proto. The remainder is the top level domain name of the web server where it is hosted.

master and develop branch docs similarly use a URL scheme https://develop.http-proto.cpp.al

Each pull request has a dedicated URL and hyperlink, and it's own folder in an S3 bucket. An nginx web server hosts the front-end, retrieving the pages from the backend S3 storage.  

## Comparison to github pages

Github pages is convenient for hosting an instance (one copy) of the documentation of a repository. If building the docs for https://github.com/cppalliance/http, then the `master` branch could be added to github pages.  

However, what about hosting separate copies of `master`, `develop`, and each separate pull request `212`, `211`, `210`, `209` , etc.  

Where would all of those be placed in github pages?

Could they each be at the "root" top level of their own domain, as it's done in the current scheme? 

Where would github pages go to retrieve the content that it needs in order to display the docs? You would not want to bloat the size of the git repository, by creating 100's of new git branches, with potentially GBs of temporary content, and then when someone runs `git clone` they must download GBs of doc previews.    

The next issue is permissions and access. Each boostorg repository has specific administrators and maintainers. The CPPAlliance is not an admin of all boost repos, and does not have access to modify setting or github pages on each repo. From the perspective of security, it would be problematic to allow a CPPAlliance bot full read/write access to many boost repositories, in order to write new branches. In comparison, the current Jenkins doc previews do not require any permissions at all, the jobs simply remotely poll the public github repos.

Next, consider "automation". At the present time, a boost developer may request doc previews, by chatting in Slack or opening a PR with a request. Granted, the setup of Jenkins is partially manually. However what usually happens, in more than 50% of cases, is there is some quirky unusual problem with a repository's docs, often library dependencies, or unusual build steps, which require human intervention. There are multiple types of docs: antora, quickbook, etc. A typical situation involves building a new library "capy" or "http-proto", which have unexpected dependencies on each other, and which use a build system that was only recently invented. Exceptions are the rule. There is always something "new". So there are two obstacles to full automation: 1. Development work, to further increase automation which is already to a certain extent present, and 2. The fact that customization is usually needed.

In summary, the architecture and design of the system in purposefully using nginx+S3+remote-polling because it's secure, manageable, maintainable in-house, and doesn't require any permissions or github access to other boost repos. Nginx and S3 are more powerful and more customizable than the limited hosting option of github pages. There are no restrictions about what features may be used with these tools.  In terms of "automation": the system is already scripted to a great extent. It is certainly imaginable to continue in that direction, and find more ways to automate.

The system as it is, evolved over months and years, it is not simple. Any given developer...  is only 1 person, who has a lot to do. There are genuinely really problems with attempting to implement this feature set on github pages, as discussed in this document. You could do something much much simpler, like help a repo publish their master branch on github pages.


