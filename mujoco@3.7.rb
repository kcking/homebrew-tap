class MujocoAT37 < Formula
  desc "MuJoCo: A general purpose physics simulator"
  homepage "https://mujoco.org"
  url "https://github.com/google-deepmind/mujoco/releases/download/3.3.7/mujoco-3.3.7-macos-universal2.dmg"
  sha256 "0076e4629f9ad482ef99d968a4ef2888bde9f30cf5726dd15027b614557ec7ba"
  license "Apache-2.0"

  depends_on :macos
  depends_on "pkg-config" => :test

  def install
    mountpoint = Dir.mktmpdir("mujoco")
    system "hdiutil", "attach", cached_download, "-mountpoint", mountpoint, "-nobrowse", "-readonly"
    source = Pathname.new(mountpoint)

    Dir.mktmpdir("mujoco-stage") do |tmp|
      staged = Pathname.new(tmp)
      cp_r source/"mujoco.framework", staged/"mujoco.framework"
      cp_r source/"MuJoCo.app/Contents/MacOS", staged/"MacOS"
      cp_r source/"model", staged/"model"
      cp_r source/"sample", staged/"sample"
      cp source/"THIRD_PARTY_NOTICES", staged/"THIRD_PARTY_NOTICES"

      frameworks.install staged/"mujoco.framework"
      libexec.install staged/"MacOS"
      (pkgshare/"model").install Dir[staged/"model/*"]
      (pkgshare/"sample").install Dir[staged/"sample/*"]
      (share/"doc/mujoco").install staged/"THIRD_PARTY_NOTICES"
    end

    %w[basic compile dependencies record simulate testspeed mujoco_plugin].each do |tool|
      (bin/tool).write_env_script libexec/"MacOS"/tool, DYLD_FRAMEWORK_PATH: frameworks
    end

    (lib/"pkgconfig").mkpath
    (lib/"pkgconfig"/"mujoco.pc").write pc_file
  ensure
    system "hdiutil", "detach", mountpoint, "-quiet" if mountpoint && Pathname.new(mountpoint).exist?
    rm_rf mountpoint if mountpoint
  end

  def pc_file
    <<~EOS
      prefix=#{prefix}
      exec_prefix=${prefix}
      libdir=${prefix}/Frameworks
      includedir=${prefix}/Frameworks/mujoco.framework/Headers

      Name: MuJoCo
      Description: General purpose physics simulator
      Version: #{version}
      Libs: -F${libdir} -framework mujoco
      Cflags: -I${includedir}
    EOS
  end

  test do
    ENV.prepend_path "PKG_CONFIG_PATH", lib/"pkgconfig"
    assert_equal version.to_s, shell_output("#{Formula["pkg-config"].opt_bin}/pkg-config --modversion mujoco").strip
    system "#{bin}/simulate", "--help"
  end
end
