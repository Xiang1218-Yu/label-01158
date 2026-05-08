#pragma once

#include <QWidget>
#include <vector>
#include "graph.h"

class MapWidget : public QWidget {
    Q_OBJECT

public:
    explicit MapWidget(QWidget *parent = nullptr);
    
    void setGraph(CampusGraph *graph);
    void setCurrentPath(const std::vector<int> &path);
    void setSelectedSpot(int spotId);
    void clearPath();

signals:
    void spotClicked(int spotId);

protected:
    void paintEvent(QPaintEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    QPointF getSpotPosition(const Spot &spot) const;
    QColor getSpotColor(const Spot &spot) const;
    
    CampusGraph *graph_ = nullptr;
    std::vector<int> currentPath_;
    int selectedSpotId_ = -1;
    
    double scale_ = 1.0;
    double offsetX_ = 0;
    double offsetY_ = 0;
    double minX_, maxX_, minY_, maxY_;
    
    void calculateTransform();
};
