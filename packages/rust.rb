require 'package'

class Rust < Package
  description 'Rust is a systems programming language that runs blazingly fast, prevents segfaults, and guarantees thread safety.'
  homepage 'https://www.rust-lang.org/'
  @_ver = '1.70.0'
  version @_ver
  license 'Apache-2.0 and MIT'
  compatibility 'all'
  source_url 'https://github.com/rust-lang/rustup.git'
  git_hashtag '1.26.0'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/rust/1.70.0_armv7l/rust-1.70.0-chromeos-armv7l.tar.zst',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/rust/1.70.0_armv7l/rust-1.70.0-chromeos-armv7l.tar.zst',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/rust/1.70.0_i686/rust-1.70.0-chromeos-i686.tar.zst',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/rust/1.70.0_x86_64/rust-1.70.0-chromeos-x86_64.tar.zst'
  })
  binary_sha256({
    aarch64: 'a8c96387d1dda9d42587ab00b2d4e5df91ae929b208204cbbb1bce0b93017900',
     armv7l: 'a8c96387d1dda9d42587ab00b2d4e5df91ae929b208204cbbb1bce0b93017900',
       i686: 'b28fcc2b3e6649e2ca473a46d930345211be027869caa77ae426b5e51f89b584',
     x86_64: '3788fc06da7adb0ba8b82b6ba63adb6d56be6518a8f9fa30070716108732e8b7'
  })

  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'zlibpkg' # R

  def self.install
    ENV['RUSTUP_PERMIT_COPY_RENAME'] = 'unstable'
    ENV['RUSTUP_INIT_SKIP_PATH_CHECK'] = 'yes'
    ENV['RUST_BACKTRACE'] = 'full'
    ENV['CARGO_HOME'] = "#{CREW_DEST_PREFIX}/share/cargo"
    ENV['RUSTUP_HOME'] = "#{CREW_DEST_PREFIX}/share/rustup"
    default_host = ARCH == 'aarch64' || ARCH == 'armv7l' ? 'armv7-unknown-linux-gnueabihf' : "#{ARCH}-unknown-linux-gnu"
    system "sed -i 's,$(mktemp -d 2>/dev/null || ensure mktemp -d -t rustup),#{CREW_PREFIX}/tmp,' rustup-init.sh"
    FileUtils.mkdir_p(CREW_DEST_HOME)
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/bin")
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/share/cargo")
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/share/rustup")
    system "RUSTFLAGS='-Clto=thin' bash ./rustup-init.sh -y --no-modify-path --default-host #{default_host} --default-toolchain #{@_ver} --profile minimal"
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/share/bash-completion/completions/")
    FileUtils.install "#{CREW_DEST_PREFIX}/share/rustup/toolchains/#{@_ver}-#{default_host}/etc/bash_completion.d/cargo",
                      "#{CREW_DEST_PREFIX}/share/bash-completion/completions/cargo", mode: 0o644
    FileUtils.rm("#{CREW_DEST_PREFIX}/share/rustup/toolchains/#{@_ver}-#{default_host}/etc/bash_completion.d/cargo")
    FileUtils.touch "#{CREW_DEST_PREFIX}/share/bash-completion/completions/rustup"
    FileUtils.mv("#{CREW_DEST_PREFIX}/share/rustup/toolchains/#{@_ver}-#{default_host}/share/man/",
                 "#{CREW_DEST_PREFIX}/share/")
    FileUtils.rm_rf("#{CREW_DEST_PREFIX}/share/rustup/toolchains/#{@_ver}-#{default_host}/share/doc/")
    FileUtils.ln_sf("#{CREW_PREFIX}/share/cargo", "#{CREW_DEST_HOME}/.cargo")
    FileUtils.ln_sf("#{CREW_PREFIX}/share/rustup", "#{CREW_DEST_HOME}/.rustup")

    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/env.d/"
    @rustconfigenv = <<~RUSTCONFIGEOF
      # Rustup and cargo configuration
      export CARGO_HOME=#{CREW_PREFIX}/share/cargo
      export RUSTUP_HOME=#{CREW_PREFIX}/share/rustup
    RUSTCONFIGEOF
    File.write("#{CREW_DEST_PREFIX}/etc/env.d/rust", @rustconfigenv)

    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/bash.d/"
    @rustcompletionenv = <<~RUSTCOMPLETIONEOF
      # Rustup and cargo bash completion
      source #{CREW_PREFIX}/share/bash-completion/completions/cargo
      source #{CREW_PREFIX}/share/bash-completion/completions/rustup
    RUSTCOMPLETIONEOF
    File.write("#{CREW_DEST_PREFIX}/etc/bash.d/rust", @rustcompletionenv)
    system "#{CREW_DEST_PREFIX}/share/cargo/bin/rustup completions bash > #{CREW_DEST_PREFIX}/share/bash-completion/completions/rustup"
    Dir.chdir "#{CREW_DEST_PREFIX}/share/cargo/bin" do
      Dir.children('.').delete_if { |f| f == 'cargo' }.each do |filename|
        FileUtils.ln_sf 'cargo', filename
      end
    end
    Dir.chdir "#{CREW_DEST_PREFIX}/bin" do
      Dir.each_child('../share/cargo/bin') do |f|
        FileUtils.ln_sf "../share/cargo/bin/#{f}", f
      end
    end
  end

  def self.postinstall
    system "rustup default #{@_ver}"
  end

  def self.remove
    config_dirs = %W[#{HOME}/.rustup #{CREW_PREFIX}/share/rustup #{HOME}/.cargo #{CREW_PREFIX}/share/cargo]
    print config_dirs
    print "\nWould you like to remove the config directories above? [y/N] "
    case $stdin.gets.chomp.downcase
    when 'y', 'yes'
      FileUtils.rm_rf config_dirs
      puts "#{config_dirs} removed.".lightgreen
    else
      puts "#{config_dirs} saved.".lightgreen
    end
  end
end
