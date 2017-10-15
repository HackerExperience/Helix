#!/bin/bash

set -e

mkdir -p graphs

mix xref graph \
    --format dot \
    --exclude lib/hell/postgrex_types.ex \
    --exclude lib/hell/hell/constant.ex \
    --exclude lib/hell/hell/directory.ex \
    --exclude lib/hell/hell/ip \
    --exclude lib/hell/hell/ltree.ex \
    --exclude lib/hell/hell/mac_addr.ex \
    --exclude lib/hell/hell/macro_helpers.ex \
    --exclude lib/hell/hell/pk.ex \
    --exclude lib/hell/hell/pk/header.ex \
    --exclude lib/hell/mix/tasks/seeds.ex \
    --exclude lib/hell/mix/tasks/test.ex  \
    --exclude lib/release.ex \
    --exclude lib/event/event.ex \
    --exclude lib/event/dispatcher.ex >> /dev/null
dot -Tpng xref_graph.dot -o graphs/overview.png

mix xref graph --format dot --source lib/event/dispatcher.ex >> /dev/null
dot -Tpng xref_graph.dot -o graphs/event_consumers.png

mix xref graph --format dot --exclude lib/event/dispatcher.ex --sink lib/event/event.ex >> /dev/null
dot -Tpng xref_graph.dot -o graphs/event_publishers.png

mix xref graph --format dot
mv xref_graph.dot graphs/xref_graph.dot

echo """
Output Graphs can be found on graphs/ folder
"""
