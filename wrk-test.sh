#!/bin/sh

wrk -t12 -c100 -d10s -s ./wrk-authorize.lua http://localhost:8808
