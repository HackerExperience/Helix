import json
from graphviz import Digraph

with open('events.json') as events_file:
    events = json.load(events_file)

handlers = events["handlers"]
flows = events["flows"]
notifiable = events["notifiable"]

def is_notifiable(name):
    return name in notifiable

def node_event(g, name):
    color = 'lightblue4' if is_notifiable(name) else 'lightblue2'
    g.node(name, shape='box', color=color, style='filled')

def node_handler(g, name):
    g.node(name, color='cornsilk', style='filled')

def node_flow(g, name):
    g.node(name, color='khaki', style='filled')

def handler_graph(g):
    for entry in handlers:
        handler = entry + ' Handler'

        for recv in handlers[entry]['receives']:
            node_event(g, recv)
            node_handler(g, handler)
            g.edge(recv, handler, label='handled by')

        for emit in handlers[entry]['emits']:
            node_event(g, emit)
            node_handler(g, handler)
            g.edge(handler, emit, label='emits')

    g.render()

def flow_graph(g):
    for entry in flows:
        flow = entry + ' Flow'

        for emit in flows[entry]:
            node_event(g, emit)
            node_flow(g, flow)
            g.edge(flow, emit, label='emits')

    g.render()

g1 = Digraph('events_handler', filename='graphs/events_handler.dot')
g1.attr(rankdir='LR')
g2 = Digraph('events_flow', filename='graphs/events_flow.dot')
g2.attr(rankdir='LR')

handler_graph(g1)
flow_graph(g2)
