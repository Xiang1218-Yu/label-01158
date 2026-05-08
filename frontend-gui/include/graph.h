#pragma once

#include <vector>
#include <string>
#include <map>
#include <limits>

// 景点信息结构
struct Spot {
    int id;
    std::string code;
    std::string name;
    std::string intro;
    double x;
    double y;
};

// 边信息结构
struct Edge {
    int from;
    int to;
    double distance;
};

// 路径结果结构
struct PathResult {
    std::vector<int> path;
    double totalDistance;
    bool found;
};

class CampusGraph {
private:
    std::vector<Spot> spots_;
    std::vector<std::vector<std::pair<int, double>>> adj_;
    std::map<std::string, int> codeToId_;

public:
    void addSpot(const Spot& spot);
    void addEdge(int from, int to, double distance);
    const std::vector<Spot>& getSpots() const;
    const Spot* getSpotById(int id) const;
    const Spot* getSpotByCode(const std::string& code) const;
    PathResult dijkstra(int startId, int endId) const;
    PathResult multiSpotPath(const std::vector<int>& spotIds) const;
    std::vector<Edge> getEdges() const;
    size_t spotCount() const { return spots_.size(); }
};
