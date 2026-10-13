"""Lifecycle animations for the dotfiles repo (ManimCE).

Four scenes: Install, Update, Uninstall, MigrateToOpt.
Every step name comes from the script it shows (see doc/animations/README.md).
Each scene is a flowchart: rounded rectangles are steps, diamonds are decisions,
arrows carry a travelling dot. No LaTeX: only Text is used.

Render one scene:
    manim -ql -o install.mp4 doc/animations/lifecycle.py Install
"""

from manim import *

# Catppuccin Mocha. configurations/themes/ holds no palette file for manim,
# so the hex values come from the Catppuccin Mocha spec.
BASE = "#1e1e2e"
MANTLE = "#181825"
SURFACE0 = "#313244"
SURFACE1 = "#45475a"
OVERLAY0 = "#6c7086"
TEXT = "#cdd6f4"
SUBTEXT = "#a6adc8"
ACCENT = "#89b4fa"  # blue: the step the flow is at now
DONE = "#a6e3a1"  # green: step or arrow already passed

config.background_color = BASE

COL_PITCH = 2.4
ROW_Y = {2: [1.35, -0.85], 3: [1.9, 0.0, -1.9]}
STEP_W, STEP_H = 1.8, 1.05
DEC_W, DEC_H = 2.0, 1.35

# state -> (fill, fill opacity, stroke, stroke width, name colour, detail colour)
STATES = {
    "idle": (SURFACE0, 1.0, SURFACE1, 3, TEXT, SUBTEXT),
    "now": (ACCENT, 0.3, ACCENT, 4, ACCENT, SUBTEXT),
    "done": (DONE, 0.22, DONE, 4, DONE, SUBTEXT),
    "skip": (MANTLE, 1.0, OVERLAY0, 2, OVERLAY0, OVERLAY0),
}


def fit(mob, max_w, max_h=None):
    """Shrink `mob` to fit the box. Never enlarge it."""
    k = min(1.0, max_w / mob.width)
    if max_h is not None:
        k = min(k, max_h / mob.height)
    if k < 1.0:
        mob.scale(k)
    return mob


class Node(VGroup):
    """A step (rounded rectangle) or a decision (diamond)."""

    def __init__(self, kind, name, detail="", num=""):
        self.kind = kind
        if kind == "decision":
            w, h = DEC_W, DEC_H
            self.shape = Polygon([w / 2, 0, 0], [0, h / 2, 0], [-w / 2, 0, 0], [0, -h / 2, 0])
        else:
            w, h = STEP_W, STEP_H
            self.shape = RoundedRectangle(corner_radius=0.14, width=w, height=h)
        self.w, self.h = w, h
        self.shape.set_fill(SURFACE0, 1).set_stroke(SURFACE1, 3)
        self.tag = None
        self.sub = None
        self.detail = detail
        if kind == "decision":
            self.title_t = fit(Text(name, font_size=18, color=TEXT, line_spacing=0.8), w * 0.58, h * 0.5)
            parts = [self.shape, self.title_t]
        else:
            self.title_t = fit(Text(name, font_size=18, color=TEXT), w - 0.2)
            self.sub = fit(Text(detail, font_size=13, color=SUBTEXT), w - 0.2)
            body = VGroup(self.title_t, self.sub).arrange(DOWN, buff=0.12)
            body.move_to(self.shape.get_center() + DOWN * 0.04)
            parts = [self.shape, body]
            if num:
                self.tag = Text(num, font_size=11, color=SUBTEXT)
                self.tag.move_to(self.shape.get_corner(UL) + RIGHT * 0.2 + DOWN * 0.15)
                parts.append(self.tag)
        super().__init__(*parts)

    def p(self, side):
        c = self.get_center()
        return c + {"l": LEFT * self.w / 2, "r": RIGHT * self.w / 2,
                    "t": UP * self.h / 2, "b": DOWN * self.h / 2}[side]

    def style(self, state, with_sub=True):
        fill, op, stroke, sw, name_c, sub_c = STATES[state]
        anims = [self.shape.animate.set_fill(fill, op).set_stroke(stroke, sw),
                 self.title_t.animate.set_color(name_c)]
        if self.sub is not None and with_sub:
            anims.append(self.sub.animate.set_color(sub_c))
        if self.tag is not None:
            anims.append(self.tag.animate.set_color(OVERLAY0 if state == "skip" else SUBTEXT))
        return anims

    def retext(self, text, color=SUBTEXT):
        """Return the animation that swaps the detail line."""
        new = fit(Text(text, font_size=13, color=color), self.w - 0.2).move_to(self.sub)
        anim = ReplacementTransform(self.sub, new)
        self.sub = new
        self.detail = text
        return anim


class Edge:
    """An orthogonal arrow with an optional yes/no label."""

    def __init__(self, pts, label=None):
        pts = [np.array([p[0], p[1], 0.0]) for p in pts]
        d = pts[-1] - pts[-2]
        d = d / np.linalg.norm(d)
        line_pts = pts[:-1] + [pts[-1] - d * 0.12]
        self.line = VMobject().set_points_as_corners(line_pts).set_stroke(OVERLAY0, 3)
        angle = np.arctan2(d[1], d[0])
        self.tip = Triangle(fill_opacity=1, stroke_width=0, color=OVERLAY0).scale(0.1)
        self.tip.rotate(angle - PI / 2).move_to(pts[-1] - d * 0.1)
        self.path = VMobject().set_points_as_corners(line_pts)
        self.length = sum(np.linalg.norm(b - a) for a, b in zip(pts[:-1], pts[1:]))
        self.label = None
        if label:
            s = pts[1] - pts[0]
            n = np.linalg.norm(s)
            u = s / n
            off = UP * 0.2 if abs(u[0]) > abs(u[1]) else RIGHT * 0.26
            self.label = Text(label, font_size=14, color=SUBTEXT)
            self.label.move_to(pts[0] + u * min(0.32, n / 2) + off)
        self.hot_line = None
        self.hot_tip = None

    def mobs(self):
        return [m for m in (self.line, self.tip, self.label) if m is not None]

    def style(self, state):
        color = {"idle": OVERLAY0, "skip": SURFACE1}[state]
        anims = [self.line.animate.set_stroke(color), self.tip.animate.set_fill(color)]
        if self.label is not None:
            anims.append(self.label.animate.set_color(OVERLAY0 if state == "skip" else SUBTEXT))
        return anims


def route(A, B, mode):
    """Return the corner points of an arrow from node A to node B."""
    if mode == "auto":
        ca, cb = A.get_center(), B.get_center()
        if abs(ca[1] - cb[1]) < 0.01:
            return [A.p("r"), B.p("l")] if cb[0] > ca[0] else [A.p("l"), B.p("r")]
        return [A.p("b"), B.p("t")] if cb[1] < ca[1] else [A.p("t"), B.p("b")]
    if mode == "over":
        a, b = A.p("t"), B.p("t")
        y = max(a[1], b[1]) + 0.3
        return [a, (a[0], y), (b[0], y), b]
    if mode == "under":
        a, b = A.p("b"), B.p("b")
        y = min(a[1], b[1]) - 0.3
        return [a, (a[0], y), (b[0], y), b]
    kind, sa, sb = mode  # ("L", side of A, side of B): one corner
    a, b = A.p(sa), B.p(sb)
    corner = (b[0], a[1]) if sa in "lr" else (a[0], b[1])
    return [a, corner, b]


def xy(col, row, rows):
    return np.array([(col - 2.5) * COL_PITCH, ROW_Y[rows][row], 0.0])


class Chart(Scene):
    """Flowchart engine: build nodes and edges, then walk the path with `go`."""

    def init_chart(self):
        self.nodes, self.edges = {}, {}
        self.cur = None
        self.cap = None
        self.title_mob = None
        self.legend = None
        self.dot = Dot(radius=0.1, color=ACCENT)
        self.pace = getattr(self, "pace", 1.0)

    # ---- chrome ----
    def set_title(self, text):
        new = Text(text, font_size=30, color=TEXT).to_edge(UP, buff=0.3)
        if self.title_mob is None:
            self.play(FadeIn(new, shift=DOWN * 0.2), run_time=0.5)
        else:
            self.play(ReplacementTransform(self.title_mob, new), run_time=0.5)
        self.title_mob = new

    def make_legend(self):
        def item(icon, word):
            return VGroup(icon, Text(word, font_size=16, color=SUBTEXT)).arrange(RIGHT, buff=0.12)

        step = RoundedRectangle(corner_radius=0.05, width=0.4, height=0.24)
        step.set_fill(SURFACE0, 1).set_stroke(SURFACE1, 2)
        dec = Polygon([0.24, 0, 0], [0, 0.17, 0], [-0.24, 0, 0], [0, -0.17, 0])
        dec.set_fill(SURFACE0, 1).set_stroke(SURFACE1, 2)
        skip = RoundedRectangle(corner_radius=0.05, width=0.4, height=0.24)
        skip.set_fill(MANTLE, 1).set_stroke(OVERLAY0, 2)
        now = Dot(radius=0.08, color=ACCENT)
        done = Dot(radius=0.08, color=DONE)
        legend = VGroup(item(step, "step"), item(dec, "decision"), item(skip, "skipped"),
                        item(now, "now"), item(done, "done"))
        legend.arrange(RIGHT, buff=0.5).to_edge(DOWN, buff=0.22)
        return legend

    def caption(self, text, run_time=0.3):
        """Return the animation that swaps the caption line."""
        new = Text(text, font_size=22, color=TEXT)
        fit(new, 13.0)
        new.move_to(DOWN * 3.2)
        if self.cap is None:
            anim = FadeIn(new)
        else:
            anim = ReplacementTransform(self.cap, new)
        self.cap = new
        return anim

    # ---- build / clear ----
    def build(self, placed, edges, rows):
        self.nodes, self.edges = {}, {}
        for nid, node, col, row in placed:
            node.move_to(xy(col, row, rows))
            self.nodes[nid] = node
        for spec in edges:
            a, b, mode = spec[0], spec[1], spec[2]
            label = spec[3] if len(spec) > 3 else None
            self.edges[(a, b)] = Edge(route(self.nodes[a], self.nodes[b], mode), label)
        self.cur = None
        if self.legend is None:
            self.legend = self.make_legend()
            extra = [FadeIn(self.legend)]
        else:
            extra = []
        mobs = [m for e in self.edges.values() for m in e.mobs()] + list(self.nodes.values())
        self.play(LaggedStart(*[FadeIn(m) for m in mobs], lag_ratio=0.03), *extra, run_time=1.3)

    def clear_chart(self):
        keep = [self.title_mob, self.legend, self.cap]
        self.play(FadeOut(*[m for m in self.mobjects if m not in keep]), run_time=0.5)
        self.cur = None

    # ---- walking the path ----
    def start(self, nid, text):
        self.cur = nid
        self.play(*self.nodes[nid].style("now"), self.caption(text), run_time=0.45)
        self.wait(0.4)

    def skip(self, nodes=(), edges=()):
        """Return the animations that grey out skipped nodes and arrows."""
        anims = []
        for n in nodes:
            anims += self.nodes[n].style("skip")
        for e in edges:
            anims += self.edges[e].style("skip")
        return anims

    def unskip(self, nodes=(), edges=()):
        anims = []
        for n in nodes:
            anims += self.nodes[n].style("idle")
        for e in edges:
            anims += self.edges[e].style("idle")
        return anims

    def go(self, a, b, text, detail=None, grey=((), ()), light=True):
        """Move a dot along arrow a->b, then light node b.

        With light=False only the arrow lights (a branch that joins a later node).
        """
        e = self.edges[(a, b)]
        t = min(1.0, max(0.35, 0.25 + 0.12 * e.length)) * self.pace
        dot = self.dot
        dot.move_to(e.path.get_start())
        e.hot_line = e.line.copy().set_stroke(ACCENT, 5)
        e.hot_tip = e.tip.copy().set_fill(ACCENT)
        self.add(dot)
        self.play(MoveAlongPath(dot, e.path, rate_func=linear), Create(e.hot_line, rate_func=linear),
                  self.caption(text), *self.skip(*grey), run_time=t)
        target = self.nodes[b]
        anims = [FadeOut(dot), FadeIn(e.hot_tip),
                 e.hot_line.animate.set_stroke(DONE, 5), e.hot_tip.animate.set_fill(DONE)]
        if light:
            if self.cur not in (None, b):
                anims += self.nodes[self.cur].style("done")
            if a != self.cur and a != b:
                anims += self.nodes[a].style("done")
            anims += target.style("now", with_sub=detail is None)
            if detail is not None:
                anims.append(target.retext(detail))
            self.cur = b
        self.play(*anims, run_time=0.3 * self.pace)
        self.wait(0.15 * self.pace)

    def finish(self):
        if self.cur is not None:
            self.play(*self.nodes[self.cur].style("done"), run_time=0.4)

    def reset(self):
        """Return every node and arrow to its idle look."""
        hots = [m for e in self.edges.values() for m in (e.hot_line, e.hot_tip) if m is not None]
        anims = [FadeOut(*hots)] if hots else []
        for n in self.nodes.values():
            anims += n.style("idle")
        for e in self.edges.values():
            anims += e.style("idle")
            e.hot_line = e.hot_tip = None
        self.play(*anims, run_time=0.8)
        self.cur = None


def step(name, detail, num=""):
    return Node("step", name, detail, num)


def decision(name):
    return Node("decision", name)


class Install(Chart):
    pace = 0.7  # longest scene: shorter beats keep the GIF under 2 MB

    def construct(self):
        self.init_chart()
        self.set_title("Install: install.sh, then setup.sh (Linux host)")
        self.build([
            ("inst", step("install.sh", "clone /opt/dotfiles"), 0, 0),
            ("l1", decision("--light?"), 1, 0),
            ("mac", decision("macOS?"), 2, 0),
            ("brew", step("Homebrew", "macOS only", "1"), 3, 0),
            ("before", step("before.sh hooks", "custom-install", "1.5"), 4, 0),
            ("pkg", step("Packages", "Brewfile or distro list", "2"), 5, 0),
            ("nat", decision("in native\nrepo?"), 5, 1),
            ("fall", step("Fallbacks", "AUR or Snap (Linux)", "3"), 4, 1),
            ("after", step("after.sh hooks", "toolchains, PATH", "3.5"), 3, 1),
            ("script", step("Script installers", "script-install.list", "3.6"), 2, 1),
            ("plug", step("Plugin managers", "vim-plug, TPM, bash-preexec", "4"), 1, 1),
            ("l2", decision("--light?"), 1, 2),
            ("skills", step("agent-skills", "repo + private mirror", "4.5"), 2, 2),
            ("links", step("Symlinks", "symlinks.sh install", "5"), 3, 2),
            ("shell", step("Login shell", "chsh to zsh", "6"), 4, 2),
            ("hook", step("lefthook", "git hooks for the repo", "7"), 5, 2),
        ], [
            ("inst", "l1", "auto"),
            ("l1", "mac", "auto", "no"),
            ("l1", "plug", "auto", "yes"),
            ("mac", "brew", "auto", "yes"),
            ("mac", "before", "under", "no"),
            ("brew", "before", "auto"),
            ("before", "pkg", "auto"),
            ("pkg", "nat", "auto"),
            ("nat", "fall", "auto", "no"),
            ("nat", "after", "under", "yes"),
            ("fall", "after", "auto"),
            ("after", "script", "auto"),
            ("script", "plug", "auto"),
            ("plug", "l2", "auto"),
            ("l2", "skills", "auto", "no"),
            ("l2", "links", "under", "yes"),
            ("skills", "links", "auto"),
            ("links", "shell", "auto"),
            ("shell", "hook", "auto"),
        ], 3)

        self.start("inst", "install.sh clones /opt/dotfiles. Group root:dotfiles, setgid.")
        self.go("inst", "l1", "setup.sh runs. Is --light set?")
        self.go("l1", "mac", "No: full install. Is this macOS?")
        self.go("mac", "before", "No: Linux. Step 1 (Homebrew) is skipped. Step 1.5: before.sh hooks.",
                grey=(["brew"], [("mac", "brew"), ("brew", "before")]))
        self.go("before", "pkg", "Step 2: install the packages from the distro list.")
        self.go("pkg", "nat", "Is each package in the native repo?")
        self.go("nat", "after", "Yes: the native repo has it. No fallback needed.", light=False)
        self.go("nat", "fall", "No: Step 3 uses a Linux fallback, AUR or Snap.")
        self.go("fall", "after", "Step 3.5: run the after.sh hooks (toolchains, PATH).")
        self.go("after", "script", "Step 3.6: run the script installers.")
        self.go("script", "plug", "Step 4: bootstrap the plugin managers.")
        self.go("plug", "l2", "Is --light set?")
        self.go("l2", "skills", "No: Step 4.5 creates agent-skills and its private mirror.")
        self.go("skills", "links", "Step 5: plant the symlinks into $HOME.")
        self.go("links", "shell", "Step 6: make zsh the login shell.")
        self.go("shell", "hook", "Step 7: install the lefthook git hooks.")
        self.finish()
        self.wait(0.8)

        # --light: the table in doc/light-profile.md
        self.set_title("setup.sh --light: second account, config only")
        self.reset()
        everything_skipped = ["mac", "brew", "before", "pkg", "nat", "fall", "after", "script"]
        skipped_edges = [("l1", "mac"), ("mac", "brew"), ("mac", "before"), ("brew", "before"),
                         ("before", "pkg"), ("pkg", "nat"), ("nat", "fall"), ("nat", "after"),
                         ("fall", "after"), ("after", "script"), ("script", "plug")]
        self.start("inst", "Second account: the repo is already at /opt/dotfiles.")
        self.go("inst", "l1", "setup.sh --light. Is --light set?")
        self.go("l1", "plug", "Yes: skip steps 1 to 3.6. Step 4 runs vim-plug and bash-preexec only.",
                detail="vim-plug, bash-preexec", grey=(everything_skipped, skipped_edges))
        self.go("plug", "l2", "Is --light set?")
        self.go("l2", "links", "Yes: skip Step 4.5. Step 5 plants LIGHT_LINKS only (17 entries).",
                detail="LIGHT_LINKS only", grey=(["skills"], [("l2", "skills"), ("skills", "links")]))
        shell = self.nodes["shell"]
        self.play(*self.skip(["hook"], [("links", "shell"), ("shell", "hook")]),
                  *shell.style("skip", with_sub=False), shell.retext("opt-in: --with-shell", OVERLAY0),
                  self.caption(
                      "Step 6 runs only with --with-shell. Step 7 is skipped."), run_time=0.8)
        self.finish()
        self.wait(1.8)


class Update(Chart):
    def construct(self):
        self.init_chart()
        self.set_title("Update: scripts/update-dotfiles (macOS host)")
        self.play(self.caption("Two layers run in order: packages, then configurations."), run_time=0.4)
        self.wait(0.6)

        # Layer 1: run_packages
        self.set_title("Packages layer")
        self.build([
            ("gp", step("git-pull", "git pull --rebase"), 0, 0),
            ("cb", step("custom-before", "before.sh hooks"), 1, 0),
            ("mac", decision("macOS?"), 2, 0),
            ("brew", step("brew", "update, upgrade, bundle"), 3, 0),
            ("ca", step("custom-after", "after.sh hooks"), 4, 0),
            ("si", step("script-install", "script-install.list"), 5, 0),
            ("nl", step("native-linux", "apt / pacman / dnf"), 2, 1),
            ("nat", decision("in native\nrepo?"), 3, 1),
            ("lf", step("linux-fallback", "AUR or Snap"), 4, 1),
        ], [
            ("gp", "cb", "auto"),
            ("cb", "mac", "auto"),
            ("mac", "brew", "auto", "yes"),
            ("mac", "nl", "auto", "no"),
            ("brew", "ca", "auto"),
            ("nl", "nat", "auto"),
            ("nat", "lf", "auto", "no"),
            ("lf", "ca", "auto"),
            ("ca", "si", "auto"),
        ], 2)
        self.start("gp", "Pull the repo (asks first, --yes skips).")
        self.go("gp", "cb", "Run the before.sh hooks.")
        self.go("cb", "mac", "Is this macOS?")
        self.go("mac", "brew", "Yes: brew update, upgrade, bundle, cleanup.",
                grey=(["nl", "nat", "lf"], [("mac", "nl"), ("nl", "nat"), ("nat", "lf"), ("lf", "ca")]))
        self.go("brew", "ca", "Run the after.sh hooks.")
        self.go("ca", "si", "Run the script installers.")
        self.finish()
        self.wait(0.8)
        self.clear_chart()

        # Layer 2: run_configurations
        self.set_title("Configurations layer")
        self.build([
            ("remote", step("agent-skills-remote", "private mirror check"), 0, 0),
            ("vendor", step("agent-skills-vendor", "re-sync vendored skills"), 1, 0),
            ("ext", step("agent-skills-external", "check out pinned submodules"), 2, 0),
            ("links", step("symlinks", "symlinks.sh install"), 3, 0),
            ("hooks", step("lefthook", "install + pre-commit run"), 4, 0),
            ("bat", step("bat-cache", "bat cache --build"), 5, 0),
            ("tq", decision("tmux server\nruns?"), 5, 1),
            ("tmux", step("tmux-reload", "source tmux.conf"), 4, 1),
            ("tpm", step("tpm", "install_plugins, clean_plugins"), 3, 1),
            ("vim", step("vim-plug", "PlugInstall, PlugClean!"), 2, 1),
            ("atuin", step("atuin-daemon", "atuin daemon restart"), 1, 1),
        ], [
            ("remote", "vendor", "auto"),
            ("vendor", "ext", "auto"),
            ("ext", "links", "auto"),
            ("links", "hooks", "auto"),
            ("hooks", "bat", "auto"),
            ("bat", "tq", "auto"),
            ("tq", "tmux", "auto", "yes"),
            ("tq", "tpm", "under", "no"),
            ("tmux", "tpm", "auto"),
            ("tpm", "vim", "auto"),
            ("vim", "atuin", "auto"),
        ], 2)
        self.start("remote", "Check the private agent-skills mirror.")
        self.go("remote", "vendor", "Vendor: re-sync third-party skills. Result stays uncommitted.")
        self.go("vendor", "ext", "External: check out pinned submodules. Never bump a pin.")
        self.go("ext", "links", "Plant any new symlinks.")
        self.go("links", "hooks", "Refresh the lefthook hooks.")
        self.go("hooks", "bat", "Rebuild the bat cache.")
        self.go("bat", "tq", "Does a tmux server run?")
        self.go("tq", "tmux", "Yes: reload tmux.conf.", grey=([], [("tq", "tpm")]))
        self.go("tmux", "tpm", "Reconcile: install the declared plugins. Prune the undeclared ones.")
        self.go("tpm", "vim", "Reconcile vim-plug the same way.")
        self.go("vim", "atuin", "Restart the atuin daemon.")
        self.finish()
        self.wait(1.2)


class Uninstall(Chart):
    def construct(self):
        self.init_chart()
        self.set_title("Uninstall: scripts/uninstall.sh")
        self.build([
            ("ledger", step("Ledger", "state.tsv, read first"), 0, 0),
            ("links", step("Symlinks", "symlinks.sh uninstall", "1"), 1, 0),
            ("inled", decision("in ledger?"), 2, 0),
            ("plug", step("Plugins", "tpm, vim-plug, bash-preexec", "2"), 3, 0),
            ("path", step("PATH segments", "strip # >>> pkg blocks", "3"), 4, 0),
            ("dirs", step("Empty dirs", "rmdir only", "4"), 5, 0),
            ("pd", decision("--purge?"), 5, 1),
            ("purge", step("Purge", "packages marked install", "5"), 4, 1),
            ("sd", decision("--shell?"), 3, 1),
            ("shell", step("Revert shell", "chsh back to old shell", "6"), 2, 1),
            ("done", step("Done", "user data stays"), 1, 1),
        ], [
            ("ledger", "links", "auto"),
            ("links", "inled", "auto"),
            ("inled", "plug", "auto", "yes"),
            ("inled", "path", "under", "no"),
            ("plug", "path", "auto"),
            ("path", "dirs", "auto"),
            ("dirs", "pd", "auto"),
            ("pd", "purge", "auto", "yes"),
            ("pd", "sd", "under", "no"),
            ("purge", "sd", "auto"),
            ("sd", "shell", "auto", "yes"),
            ("sd", "done", "over", "no"),
            ("shell", "done", "auto"),
        ], 2)
        self.start("ledger", "The ledger lists what this repo planted. Read it first.")
        self.go("ledger", "links", "Step 1: remove every symlink. The ledger cross-checks.")
        self.go("links", "inled", "Step 2: is the plugin checkout in the ledger?")
        self.go("inled", "plug", "Yes: remove the plugin checkouts the ledger records.",
                grey=([], [("inled", "path")]))
        self.go("plug", "path", "Step 3: strip the PATH segments from ~/.dotfiles/path.")
        self.go("path", "dirs", "Step 4: rmdir the empty directories. Files survive.")
        self.go("dirs", "pd", "Steps 5 and 6 are off by default. Is --purge set?")
        self.go("pd", "sd", "No: skip Step 5. Is --shell set?",
                grey=(["purge"], [("pd", "purge"), ("purge", "sd")]))
        self.go("sd", "done", "No: skip Step 6. Never touched: credentials, history, keys, user data.",
                grey=(["shell"], [("sd", "shell"), ("shell", "done")]))
        self.finish()
        self.wait(1.2)

        # The opt-in branches
        self.set_title("Uninstall with --purge and --shell")
        self.play(*self.unskip(["purge", "shell"], [("pd", "purge"), ("purge", "sd"), ("sd", "shell"),
                                                    ("shell", "done")]),
                  *self.nodes["done"].style("idle"), self.caption("With both flags, Steps 5 and 6 run."),
                  run_time=0.8)
        self.cur = None
        self.go("pd", "purge", "--purge: remove ledger packages marked install. Never present ones.")
        self.go("purge", "sd", "Is --shell set?")
        self.go("sd", "shell", "Yes: --shell reverts the login shell to the recorded one.")
        self.go("shell", "done", "Never touched: credentials, history, keys, user data.")
        self.finish()
        self.wait(1.8)


class MigrateToOpt(Chart):
    def construct(self):
        self.init_chart()
        self.set_title("Migrate: scripts/migrate-to-opt.sh")
        self.build([
            ("src", step("~/gel-ort/dotfiles", "dev checkout"), 0, 0),
            ("dirty", decision("dirty?"), 1, 0),
            ("user", step("Per-user state", ".load, .path to ~/.dotfiles/", "2"), 2, 0),
            ("same", decision("same\ndevice?"), 3, 0),
            ("mv", step("Relocate: mv", "to /opt/dotfiles", "3"), 4, 0),
            ("stop", step("Stop", "uncommitted changes", "1"), 1, 1),
            ("clone", step("Relocate: clone", "git clone to /opt/dotfiles", "3"), 3, 1),
            ("repoint", step("Repoint links", "symlinks.sh install", "4"), 4, 1),
            ("verify", step("Verify links", "report dangling count", "4"), 5, 1),
            ("old", step("Old checkout", "never deleted", "5"), 5, 2),
            ("grp", step("root:dotfiles", "set by install.sh, not here"), 4, 2),
        ], [
            ("src", "dirty", "auto"),
            ("dirty", "user", "auto", "no"),
            ("dirty", "stop", "auto", "yes"),
            ("user", "same", "auto"),
            ("same", "mv", "auto", "yes"),
            ("same", "clone", "auto", "no"),
            ("mv", "repoint", "auto"),
            ("clone", "repoint", "auto"),
            ("repoint", "verify", "auto"),
            ("verify", "old", "auto"),
            ("old", "grp", "auto"),
        ], 3)
        self.start("src", "The source is a dev checkout. The target is /opt/dotfiles.")
        self.go("src", "dirty", "Step 1: does the source repo have uncommitted changes?")
        self.go("dirty", "user", "No: go on. Step 2: move .load and .path to ~/.dotfiles/ first.",
                grey=(["stop"], [("dirty", "stop")]))
        self.go("user", "same", "Step 3: relocate the repo. Same device as /opt?")
        self.go("same", "mv", "Yes: mv the repo to /opt/dotfiles.",
                grey=(["clone"], [("same", "clone"), ("clone", "repoint")]))
        self.go("mv", "repoint", "Step 4: repoint every symlink to /opt/dotfiles.")
        self.go("repoint", "verify", "Step 4: check that no link dangles.")
        self.go("verify", "old", "Step 5: the old checkout stays. You remove it by hand.")
        self.go("old", "grp", "Group and setgid come from install.sh (provision-shared-group.sh).")
        self.finish()
        self.wait(3.0)
