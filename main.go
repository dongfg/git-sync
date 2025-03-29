package main

import (
	"fmt"
	"github.com/go-git/go-git/v5/config"
	"os"
	"os/exec"
	"strings"

	"github.com/go-git/go-git/v5"
	"gopkg.in/ini.v1"
)

type GitRemote struct {
	URLs []string
}

var GitConfigName = ".gitconfig"

func parseConfigRemote() *GitRemote {
	gr := &GitRemote{}
	cfg, err := ini.LoadSources(ini.LoadOptions{AllowShadows: true}, GitConfigName)
	if err != nil {
		fmt.Println(".gitconfig not found")
		return nil
	}
	s, err := cfg.GetSection("remote \"origin\"")
	if err != nil {
		fmt.Println("remote \"origin\" not found")
		return nil
	}
	gr.URLs = append(gr.URLs, s.Key("url").ValueWithShadows()...)
	gr.URLs = append(gr.URLs, s.Key("pushurl").ValueWithShadows()...)
	gr.URLs = removeDuplicate(gr.URLs)
	return gr
}

func readRepoRemote(repo *git.Repository) *GitRemote {
	gr := &GitRemote{}
	remotes, err := repo.Remotes()
	if err != nil || len(remotes) == 0 {
		return nil
	}
	gr.URLs = remotes[0].Config().URLs
	gr.URLs = removeDuplicate(gr.URLs)
	return gr
}

func save(gr *GitRemote) {
	cfg := strings.Builder{}
	cfg.WriteString("[remote \"origin\"]\n")

	// 设置 url
	for _, url := range gr.URLs {
		cfg.WriteString(fmt.Sprintf("url = %s\n", url))
	}

	_ = os.WriteFile(GitConfigName, []byte(cfg.String()), 0666)
}

func apply(repo *git.Repository, gr *GitRemote) {
	_ = repo.DeleteRemote("origin")
	_, _ = repo.CreateRemote(&config.RemoteConfig{
		Name: "origin",
		URLs: gr.URLs,
	})
	remotes, _ := repo.Remotes()
	if len(remotes) > 0 {
		grv := exec.Command("git", "remote", "-v")
		output, _ := grv.CombinedOutput()
		fmt.Println(string(output))
	}
}

func removeDuplicate[T comparable](sliceList []T) []T {
	allKeys := make(map[T]bool)
	var list []T
	for _, item := range sliceList {
		if _, value := allKeys[item]; !value {
			allKeys[item] = true
			list = append(list, item)
		}
	}
	return list
}

func main() {
	repo, err := git.PlainOpen(".")
	if err != nil {
		fmt.Println("git repo not found")
		return
	}

	// 检查命令行参数
	args := os.Args[1:]
	if len(args) == 0 {
		// apply config
		cr := parseConfigRemote()
		if cr == nil {
			return
		}
		apply(repo, cr)
	} else if args[0] == "save" {
		// save config
		rr := readRepoRemote(repo)
		if rr == nil {
			return
		}
		save(rr)
	} else {
		fmt.Println("invalid args")
	}
}
