txt = Import["C:/Users/cp/.claude/projects/C--Users-cp-Desktop-black-box--claude-worktrees-mystifying-galileo-871da6/b51791ad-fd3f-40b3-8ee6-b0495d72216a/tool-results/webfetch-1783872733992-rvs3sh.pdf", "Plaintext"];
Print["length: ", StringLength[txt]];
Export["C:/Users/cp/Desktop/black-box/glv_paper_text.txt", txt, "Text"];
Print["exported"];
