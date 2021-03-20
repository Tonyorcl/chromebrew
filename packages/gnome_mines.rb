require 'package'

class Gnome_mines < Package
  description 'GNOME Mines (formerly known as Gnomine) is minesweeper clone for GNOME'
  homepage 'https://wiki.gnome.org/Apps/Mines'
  @_app = File.basename(__FILE__, '.rb').tr('_', '-')
  @_fullver = '3.36.1'
  @_mainver = @_fullver.rpartition('.')[0]
  @_url = "https://download.gnome.org/sources/#{@_app}/#{@_mainver}/#{@_app}-#{@_fullver}"
  version @_fullver
  license 'GPL-3+ and CC-BY-SA-3.0'
  compatibility 'all'
  source_url "#{@_url}.tar.xz"
  source_sha256 `curl -Ls #{@_url}.sha256sum | tail -n1 | cut -d ' ' -f1`.chomp

  depends_on 'clutter_gtk'
  depends_on 'gsound'
  depends_on 'librsvg'
  depends_on 'libgnome_games_support'

  def self.build
    system "env CFLAGS='-fuse-ld=lld' CXXFLAGS='-fuse-ld=lld' \
            meson #{CREW_MESON_LTO_OPTIONS} builddir"
    system 'meson configure builddir'
    system 'ninja -C builddir'
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} ninja -C builddir install"
    @_wrapper = <<~EOF
      #!/bin/sh
      WAYLAND_DISPLAY=wayland-0
      GDK_BACKEND=wayland
      CLUTTER_BACKEND=wayland
      exec #{@_app}.elf "$@"
    EOF
    File.write(@_app, @_wrapper)
    FileUtils.mv "#{CREW_DEST_PREFIX}/bin/#{@_app}", "#{CREW_DEST_PREFIX}/bin/#{@_app}.elf"
    FileUtils.install @_app, "#{CREW_DEST_PREFIX}/bin/#{@_app}", mode: 0755
  end

  def self.postinstall
    system 'gdk-pixbuf-query-loaders --update-cache'
    system "glib-compile-schemas #{CREW_PREFIX}/share/glib-2.0/schemas"
  end
end
