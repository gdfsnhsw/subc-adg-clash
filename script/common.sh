#!/bin/bash

# clash tun scripts configuration

# cgroup net_cls classid
readonly BYPASS_CGROUP_CLASSID=10000

# netfilter mark
readonly NETFILTER_MARK=100

# iproute2 rule table id
readonly IPROUTE2_TABLE_ID=100

# dns redirect
readonly FORWARD_DNS_REDIRECT=:1053

# tproxy (TProxy TCP and TProxy UDP) or Redir (Redirect TCP and TProxy UDP)
readonly FORWARD_PROXY_REDIRECT=:7893
