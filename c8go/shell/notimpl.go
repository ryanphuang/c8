package shell

import (
	"fmt"
	"io"
)

func notImpl(args []string, out io.Writer) int {
	cmd := args[0]
	fmt.Fprintf(out, "command %q not implemented yet\n", cmd)
	return -1
}
