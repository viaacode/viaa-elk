#!/usr/bin/env bash

echo > /dev/tcp/0.0.0.0/9200 || echo `date` rediness failed
