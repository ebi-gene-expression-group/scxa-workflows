

"""
Given a set of clustering files, choose resolutions to use for colliding number of clusters, merge cluster files
into a single file and move markers from resolutions to applicable clusters number.
"""

import argparse
from os import listdir
import re
import shutil


def num_of_clusters(file_path):
    clusters = set()
    f = open(file_path)
    f.readline()  # discard header
    for line in f:
        cluster = line.split(sep="\t")[1]
        clusters.add(cluster)
    return len(clusters)


def main():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('-c', '--clusters-path',
                            required=True,
                            help='Path to where cluster files are found')
    arg_parser.add_argument('-o', '--output-dir',
                            required=True,
                            help='Path for results')

    args = arg_parser.parse_args()

    # Pattern to extract resolution value from clusters file residing in clusters-path, supports integer or floats res.
    clusters_file_pat = re.compile(r'clusters_resolution_(?P<resolution>\d+\.?\d*).tsv')

    clusters_to_res = {}
    # Choose resolutions and map to cluster numbers
    for cluster_file in listdir(args.clusters_path):
        match = re.search(clusters_file_pat, cluster_file)
        if match is not None:
            resolution = match.group('resolution')
            clusters = num_of_clusters(args.clusters_path+"/"+cluster_file)
            if clusters in clusters_to_res:
                if clusters_to_res[clusters] > resolution >= 1 or 1 >= resolution > clusters_to_res[clusters]:
                    # the current resolution is closer to 1, we prefer it
                    clusters_to_res[clusters] = resolution
            else:
                clusters_to_res[clusters] = resolution

    # Merge all clusters for the selected resolutions into memory and
    # create individual marker files for each clustering value
    cells_set = set()
    cells_clusters = {}
    for clusters, resolution in sorted(clusters_to_res.items()):
        print("Res: {} --> Cluster: {}".format(resolution, clusters))
        clusters_source = open(args.clusters_path+"/clusters_resolution_"+str(resolution)+".tsv", mode="r")
        header = clusters_source.readline()
        cluster_assignment = {}
        for line in clusters_source:
            cell, cluster_num = line.rstrip().split(sep="\t")
            cells_set.add(cell)
            cluster_assignment[cell] = cluster_num
        cells_clusters[clusters] = cluster_assignment

        source = args.clusters_path+"/markers_clusters_resolution_"+str(resolution)+".csv"
        dest = args.output_dir+"/markers_"+str(clusters)+".csv"
        shutil.copy(source, dest)

    print("Cell set has {} entries".format(len(cells_set)))
    print("Cell clusters has {} entries".format(len(cells_clusters)))
    # Write the complete clusters file in order
    clusters_output = open(args.output_dir + "/clusters_for_bundle.txt", mode="w")
    clusters_output.write("sel.K\tK\t"+"\t".join(sorted(cells_set))+"\n")
    for k, cluster_assignment in sorted(cells_clusters.items()):
        selected = 'TRUE' if float(clusters_to_res[k]) == 1.0 else 'FALSE'
        clusters_output.write("\t".join([selected, str(k)]))
        print("Cluster assignments for k {} has {} entries".format(k, len(cluster_assignment)))
        for cell in sorted(cells_set):
            clusters_output.write("\t"+str(cluster_assignment[cell]))
        clusters_output.write("\n")


if __name__ == '__main__':
    main()