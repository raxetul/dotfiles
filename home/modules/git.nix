{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Emrah URHAN";
      user.email = "raxetul@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    includes = [
      {
        condition = "gitdir:~/personal/";
        contents.user.email = "raxetul@gmail.com";
      }
      {
        condition = "gitdir:~/workspace/";
        contents.user.email = "emrahurhan@buyutech.com.tr";
      }
    ];
  };
}
