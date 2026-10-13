"""Lifecycle animations for the dotfiles repo (ManimCE).

Four scenes: Install, Update, Uninstall, MigrateToOpt.
Every step name comes from the script it shows (see doc/animations/README.md).
No LaTeX: only Text is used.

Render one scene:
    manim -ql --format gif -o install.gif doc/animations/lifecycle.py Install
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
GREEN = "#a6e3a1"
YELLOW = "#f9e2af"
PEACH = "#fab387"
BLUE = "#89b4fa"
MAUVE = "#cba6f7"

config.background_color = BASE

CARD_W = 3.1
CARD_H = 1.25
GAP = 0.2


class Card(VGroup):
    """One step: a rounded rectangle, a number tag, a name, and a detail line."""

    def __init__(self, num, name, detail, width=CARD_W, height=CARD_H):
        self.rect = RoundedRectangle(
            corner_radius=0.15, width=width, height=height,
            fill_color=SURFACE0, fill_opacity=1, stroke_color=SURFACE1, stroke_width=3,
        )
        parts = []
        self.tag = Text(num, font_size=22, color=MAUVE) if num else None
        self.title_t = Text(name, font_size=22, color=TEXT)
        head = VGroup(*([self.tag] if self.tag else []), self.title_t).arrange(RIGHT, buff=0.15)
        self.sub = self._detail(detail, width)
        self.label = VGroup(head, self.sub).arrange(DOWN, buff=0.15)
        if self.label.width > width - 0.3:
            self.label.scale((width - 0.3) / self.label.width)
        self.label.move_to(self.rect)
        super().__init__(self.rect, self.label)

    @staticmethod
    def _detail(text, width):
        detail = Text(text, font_size=16, color=SUBTEXT)
        if detail.width > width - 0.3:
            detail.scale((width - 0.3) / detail.width)
        return detail

    def paint(self, color, fill=0.25):
        """Animations that light the card in `color`."""
        return [
            self.rect.animate.set_fill(color, fill).set_stroke(color, 4),
            self.title_t.animate.set_color(color),
        ]

    def grey(self):
        """Animations that grey the card out (skipped step)."""
        anims = [
            self.rect.animate.set_fill(MANTLE, 1).set_stroke(OVERLAY0, 2),
            self.title_t.animate.set_color(OVERLAY0),
            self.sub.animate.set_color(OVERLAY0),
        ]
        if self.tag:
            anims.append(self.tag.animate.set_color(OVERLAY0))
        return anims

    def retext(self, text):
        """Return the animation that swaps the detail line."""
        new = self._detail(text, self.rect.width).move_to(self.sub).set_color(SUBTEXT)
        anim = ReplacementTransform(self.sub, new)
        self.sub = new
        return anim


class Flow(Scene):
    """Shared helpers: title, caption, card grid."""

    title_mob = None
    caption_mob = None

    def set_title(self, text, color=MAUVE):
        new = Text(text, font_size=34, color=color).to_edge(UP, buff=0.3)
        if self.title_mob is None:
            self.play(FadeIn(new, shift=DOWN * 0.2), run_time=0.6)
        else:
            self.play(ReplacementTransform(self.title_mob, new), run_time=0.6)
        self.title_mob = new

    def caption(self, text, color=SUBTEXT, run_time=0.4):
        new = Text(text, font_size=22, color=color).to_edge(DOWN, buff=0.35)
        if new.width > 13:
            new.scale(13 / new.width)
        if self.caption_mob is None:
            self.play(FadeIn(new), run_time=run_time)
        else:
            self.play(ReplacementTransform(self.caption_mob, new), run_time=run_time)
        self.caption_mob = new

    def grid(self, specs, cols=4, shift=DOWN * 0.1):
        cards = [Card(*s) for s in specs]
        rows = (len(cards) + cols - 1) // cols
        VGroup(*cards).arrange_in_grid(rows=rows, cols=cols, buff=GAP)
        VGroup(*cards).move_to(ORIGIN).shift(shift)
        return cards

    def show(self, cards):
        self.play(LaggedStart(*[FadeIn(c, scale=0.9) for c in cards], lag_ratio=0.08), run_time=1.4)

    def step(self, card, text, color=GREEN, hold=0.35):
        self.caption(text, run_time=0.25)
        self.play(*card.paint(color), run_time=0.3)
        self.wait(hold)

    def clear(self):
        self.play(FadeOut(*[m for m in self.mobjects if m is not self.title_mob and m is not self.caption_mob]),
                  run_time=0.5)


class Install(Flow):
    def construct(self):
        self.set_title("Install: install.sh, then setup.sh")
        cards = self.grid([
            ("", "install.sh", "/opt/dotfiles, root:dotfiles"),
            ("1", "Homebrew", "macOS only"),
            ("1.5", "before.sh hooks", "custom-install"),
            ("2", "Packages", "Brewfile or distro list"),
            ("3", "Fallbacks", "AUR or Snap (Linux)"),
            ("3.5", "after.sh hooks", "toolchains, PATH segments"),
            ("3.6", "Script installers", "script-install.list"),
            ("4", "Plugin managers", "vim-plug, TPM, bash-preexec"),
            ("4.5", "agent-skills", "repo + private mirror"),
            ("5", "Symlinks", "symlinks.sh install"),
            ("6", "Login shell", "chsh to zsh"),
            ("7", "lefthook", "git hooks for the repo"),
        ])
        self.show(cards)
        (c_inst, c1, c15, c2, c3, c35, c36, c4, c45, c5, c6, c7) = cards

        self.step(c_inst, "install.sh clones /opt/dotfiles. Group root:dotfiles, setgid.", BLUE, 0.8)
        self.caption("Full install: setup.sh runs each step in order.", run_time=0.3)
        self.wait(0.6)
        self.step(c1, "Step 1: install Homebrew (macOS only).")
        self.step(c15, "Step 1.5: run before.sh hooks (repos, keys).")
        self.step(c2, "Step 2: install the packages.")
        self.step(c3, "Step 3: Linux fallbacks, AUR or Snap.")
        self.step(c35, "Step 3.5: run after.sh hooks (toolchains, PATH).")
        self.step(c36, "Step 3.6: run script installers.")
        self.step(c4, "Step 4: bootstrap the plugin managers.")
        self.step(c45, "Step 4.5: create agent-skills and its private mirror.")
        self.step(c5, "Step 5: plant the symlinks into $HOME.")
        self.step(c6, "Step 6: make zsh the login shell.")
        self.step(c7, "Step 7: install the lefthook git hooks.")
        self.wait(1.0)

        # --light: the table in doc/light-profile.md
        self.set_title("setup.sh --light: second account, config only", YELLOW)
        self.caption("--light skips every step that installs packages.")
        self.play(*[a for c in (c1, c15, c2, c3, c35, c36) for a in c.grey()], run_time=1.0)
        self.wait(0.6)
        self.caption("It also skips agent-skills and lefthook.")
        self.play(*[a for c in (c45, c7) for a in c.grey()], run_time=0.8)
        self.wait(0.6)
        self.caption("Step 4 runs vim-plug and bash-preexec only. TPM is skipped.")
        self.play(*c4.paint(YELLOW), c4.retext("vim-plug, bash-preexec"), run_time=0.8)
        self.wait(0.7)
        self.caption("Step 5 plants LIGHT_LINKS only (17 entries).")
        self.play(*c5.paint(YELLOW), c5.retext("LIGHT_LINKS only"), run_time=0.8)
        self.wait(0.7)
        self.caption("Step 6 runs only with --with-shell.")
        self.play(*c6.paint(YELLOW), c6.retext("opt-in: --with-shell"), run_time=0.8)
        self.wait(1.5)


class Update(Flow):
    def construct(self):
        self.set_title("Update: scripts/update-dotfiles")
        self.caption("Two layers run in order: packages, then configurations.")
        self.wait(0.8)

        # Layer 1: run_packages
        self.set_title("Packages layer")
        pk = self.grid([
            ("", "git-pull", "git pull --rebase"),
            ("", "custom-before", "before.sh hooks"),
            ("", "brew", "update, upgrade, bundle"),
            ("", "native-linux", "apt / pacman / dnf"),
            ("", "linux-fallback", "AUR or Snap"),
            ("", "custom-after", "after.sh hooks"),
            ("", "script-install", "script-install.list"),
        ])
        self.show(pk)
        notes = [
            "Pull the repo (asks first, --yes skips).",
            "Run the before.sh hooks.",
            "macOS: brew update, upgrade, bundle, cleanup.",
            "Linux: install from the distro lists.",
            "Linux: AUR or Snap for what native lacks.",
            "Run the after.sh hooks.",
            "Run the script installers.",
        ]
        for card, text in zip(pk, notes):
            self.step(card, text, GREEN, 0.25)
        self.wait(0.6)
        self.clear()

        # Layer 2: run_configurations
        self.set_title("Configurations layer")
        cf = self.grid([
            ("", "agent-skills-remote", "private mirror check"),
            ("", "agent-skills-vendor", "re-sync vendored skills"),
            ("", "agent-skills-external", "check out pinned submodules"),
            ("", "symlinks", "symlinks.sh install"),
            ("", "lefthook", "install + pre-commit run"),
            ("", "bat-cache", "bat cache --build"),
            ("", "tmux-reload", "source tmux.conf"),
            ("", "tpm", "install_plugins, clean_plugins"),
            ("", "vim-plug", "PlugInstall, PlugClean!"),
            ("", "atuin-daemon", "atuin daemon restart"),
        ])
        self.show(cf)
        (remote, vendor, external, links, hooks, bat, tmux, tpm, vimplug, atuin) = cf
        self.step(remote, "Check the private agent-skills mirror.")
        self.step(vendor, "Vendor: re-sync third-party skills. Result stays uncommitted.")
        self.step(external, "External: check out pinned submodules. Never bump a pin.")
        self.step(links, "Plant any new symlinks.")
        self.step(hooks, "Refresh the lefthook hooks.", GREEN, 0.2)
        self.step(bat, "Rebuild the bat cache.", GREEN, 0.2)
        self.step(tmux, "Reload tmux.conf if a tmux server runs.", GREEN, 0.2)
        self.caption("Reconcile: install the declared plugins. Prune the undeclared ones.", PEACH)
        self.play(*tpm.paint(PEACH), run_time=0.5)
        self.wait(0.8)
        self.play(*vimplug.paint(PEACH), run_time=0.5)
        self.wait(0.8)
        self.step(atuin, "Restart the atuin daemon.", GREEN, 0.2)
        self.wait(1.2)


class Uninstall(Flow):
    def construct(self):
        self.set_title("Uninstall: scripts/uninstall.sh")
        ledger = Card("", "Realized-state ledger", "~/.local/state/dotfiles/state.tsv", width=6.4)
        ledger.to_edge(UP, buff=1.0)
        cards = self.grid([
            ("1", "Symlinks", "symlinks.sh uninstall"),
            ("2", "Plugins", "tpm, vim-plug, bash-preexec"),
            ("3", "PATH segments", "strip # >>> pkg blocks"),
            ("4", "Empty dirs", "rmdir only"),
            ("5", "--purge", "packages marked install"),
            ("6", "--shell", "chsh back to old shell"),
        ], cols=3, shift=DOWN * 0.9)
        self.play(FadeIn(ledger, shift=DOWN * 0.2), run_time=0.6)
        self.show(cards)
        s1, s2, s3, s4, s5, s6 = cards

        self.caption("The ledger lists what this repo planted. Read it first.", BLUE)
        self.play(*ledger.paint(BLUE), run_time=0.5)
        self.wait(0.9)

        self.step(s1, "Step 1: remove every symlink. The ledger cross-checks.")
        self.play(Indicate(ledger, color=BLUE, scale_factor=1.04), run_time=0.5)
        self.step(s2, "Step 2: remove the plugin checkouts the ledger records.")
        self.play(Indicate(ledger, color=BLUE, scale_factor=1.04), run_time=0.5)
        self.step(s3, "Step 3: strip the PATH segments from ~/.dotfiles/path.")
        self.step(s4, "Step 4: rmdir the empty directories. Files survive.")
        self.wait(0.5)

        self.caption("Steps 5 and 6 are off by default.")
        self.play(*s5.grey(), *s6.grey(), run_time=0.8)
        self.wait(1.0)
        self.caption("--purge removes ledger packages marked install. Never present ones.", YELLOW)
        self.play(*s5.paint(YELLOW), Indicate(ledger, color=BLUE, scale_factor=1.04), run_time=0.8)
        self.wait(1.2)
        self.caption("--shell reverts the login shell to the recorded one.", YELLOW)
        self.play(*s6.paint(YELLOW), Indicate(ledger, color=BLUE, scale_factor=1.04), run_time=0.8)
        self.wait(1.2)
        self.caption("Never touched: credentials, history, keys, user data.", GREEN)
        self.wait(1.8)


class MigrateToOpt(Flow):
    def construct(self):
        self.set_title("Migrate: scripts/migrate-to-opt.sh")
        src = Card("", "~/gel-ort/dotfiles", "dev checkout", width=4.0, height=0.9)
        dst = Card("", "/opt/dotfiles", "shared repo", width=4.0, height=0.9)
        strip = VGroup(src, dst).arrange(RIGHT, buff=2.2).to_edge(UP, buff=1.0)
        arrow = Arrow(src.get_right(), dst.get_left(), buff=0.15, color=OVERLAY0)
        cards = self.grid([
            ("1", "Dirty check", "stop if uncommitted"),
            ("2", "Per-user state", ".load, .path to ~/.dotfiles/"),
            ("3", "Relocate repo", "mv, or git clone"),
            ("4", "Repoint links", "symlinks.sh install"),
            ("4", "Verify links", "report dangling count"),
            ("5", "Old checkout", "never deleted"),
            ("", "root:dotfiles, setgid", "not set by this script"),
        ], shift=DOWN * 1.0)
        self.play(FadeIn(strip, shift=DOWN * 0.2), GrowArrow(arrow), run_time=0.7)
        self.show(cards)
        c1, c2, c3, c4, c4b, c5, grp = cards
        self.play(*src.paint(BLUE), run_time=0.4)

        self.step(c1, "Step 1: stop if the source repo has uncommitted changes.")
        self.step(c2, "Step 2: move .load and .path to ~/.dotfiles/ first.")
        self.caption("Step 3: relocate the repo. Same device: mv. Else: git clone.")
        self.play(*c3.paint(GREEN), *dst.paint(GREEN), Indicate(arrow, color=GREEN), run_time=0.8)
        self.wait(0.8)
        self.step(c4, "Step 4: repoint every symlink to /opt/dotfiles.")
        self.step(c4b, "Step 4: check that no link dangles.")
        self.caption("Step 5: the old checkout stays. You remove it by hand.", YELLOW)
        self.play(*c5.paint(YELLOW), run_time=0.5)
        self.wait(1.0)
        self.caption("Group and setgid come from install.sh (provision-shared-group.sh).", BLUE)
        self.play(*grp.paint(BLUE, 0.12), run_time=0.5)
        self.wait(2.2)
