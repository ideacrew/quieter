# quieter

This is a small project to get some reports that are not easy to get from the github webpage. Right now the most important one is to
get the list of PR that are related to all the commits between two sha's.

# Requeriments

- Ruby 3.2.2
- Node 18 (it may work on higher versions, but not on lower)

## Installation

right now is not prepared to go to production, for development, clone repo and create a .env file with the following content

```
GH_TOKEN=your_github_token
```

then run the following commands

```
rails s
```

