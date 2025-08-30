package template

import (
	"embed"
	"io/fs"
	"path/filepath"
	"slices"
)

//go:embed certs
var Certs embed.FS

//go:embed ipxe
var Ipxe embed.FS

//go:embed mkboot
var Mkboot embed.FS

//go:embed dist
var Dist embed.FS

func DistNames() ([]string, error) {
	paths, err := fs.Glob(Dist, "dist/*")
	if err != nil {
		return []string{}, Fatal(err)
	}
	slices.Sort(paths)
	osList := []string{}
	for _, path := range paths {
		_, name := filepath.Split(path)
		osList = append(osList, name)
	}
	return osList, nil
}

func DistVersions(distName string) ([]string, error) {
	distPath := filepath.Join("dist", distName)
	paths, err := fs.Glob(Dist, filepath.Join(distPath, "*"))
	if err != nil {
		return []string{}, Fatal(err)
	}
	if len(paths) == 0 {
		return []string{}, Fatalf("unknown OS: %s", distName)
	}
	slices.Sort(paths)
	versionList := []string{}
	for _, path := range paths {
		_, version := filepath.Split(path)
		versionList = append(versionList, version)
	}
	return versionList, nil
}
