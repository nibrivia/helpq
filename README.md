# helpq
[![Travis-CI Build Status](https://travis-ci.org/nibrivia/helpq.svg?branch=master)](https://travis-ci.org/nibrivia/helpq)
[![Coverage Status](https://img.shields.io/codecov/c/github/nibrivia/helpq/master.svg)](https://codecov.io/github/nibrivia/helpq?branch=master)


The goal of helpq is to have a central location for all of the 6.004 queue related code.

## Installation

You can install helpq from github with:

```R
# install.packages("devtools")
devtools::install_github("helpq/nibrivia")
```

## Authentication

Bits of this package require authentication. These are not yet nicely unified.

### Queue

The queue datalog is in a database. You need to have an ODBC setup that allows
you to access it as `helpq`.

### Staffing


The staff schedule requires a 6.004 account to access. The credentials should be
stored in environment variables `helpq_username` and `helpq_password`.