import { View, div } from "gpui-kit";
import { layout, run, closeOverlay, props } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// A one-shot launcher: use the same sidebar behavior as the Changes button.
export default class ToggleChanges extends View {
  init(_props, cx) {
    const overlay = props()?.overlay;
    if (!overlay) return;
    cx.timer.after(1, () => {
      const root = layout();
      const panel = find(root, "panel");
      const body = find(root, "panel-body");
      if (panel && body) {
        if (!panel.hidden && body.active === "changes") {
          run("layout.hide", { id: "panel" });
        } else {
          run("layout.select", { stack: "panel-body", child: "changes" });
          run("layout.show", { id: "panel" });
        }
      }
      closeOverlay(overlay);
    });
  }

  render() {
    return div().size(1);
  }
}
