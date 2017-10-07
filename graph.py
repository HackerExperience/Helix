import json
from graphviz import Digraph

with open('events.json') as events_file:
    events = json.load(events_file)

handlers = events["handlers"]
flows = events["flows"]
notificable = events["notificable"]
missions = events["missions"]
process_conclusion = events["process_conclusion"]

def is_notificable(name):
    return name in notificable

def node_event(g, name):
    color = 'lightblue4' if is_notificable(name) else 'lightblue2'
    g.node(name, shape='box', color=color, style='filled')

def node_handler(g, name):
    g.node(name, color='cornsilk', style='filled')

def node_flow(g, name):
    g.node(name, color='khaki', style='filled')

def node_step(g, name):
    g.node(name, color='darkolivegreen3', style='filled')

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

    top = "On Process Completion"
    for processed in process_conclusion:
        node_event(g, processed)
        node_handler(g, top)
        g.edge(top, processed, label='emits')

    g.render()

def flow_graph(g):
    for entry in flows:
        flow = entry + ' Flow'

        for emit in flows[entry]:
            node_event(g, emit)
            node_flow(g, flow)
            g.edge(flow, emit, label='emits')

    g.render()

def mission_graph(g):
    for mission in missions:

        with g.subgraph(name='cluster_' + mission) as gm:
            gm.attr(label=mission + ' Mission', color='red')

            for step in missions[mission]['steps']:
                step_data = missions[mission]['steps'][step]
                step = step + ' Step'

                for filtered in step_data['filters']:
                    node_event(gm, filtered)
                    node_step(gm, step)
                    gm.edge(step, filtered, label='filters')

                for emit in step_data['emits']:
                    node_event(gm, emit)
                    node_step(gm, step)
                    gm.edge(step, emit, label='emits')

    g.render()


g1 = Digraph('events_handler', filename='graphs/events_handler.dot')
g2 = Digraph('events_flow', filename='graphs/events_flow.dot')
g3 = Digraph('events_missions', filename='graphs/events_missions.dot')

g1.attr(rankdir='LR')
g2.attr(rankdir='LR')
g3.attr(rankdir='LR')

handler_graph(g1)
flow_graph(g2)
mission_graph(g3)
