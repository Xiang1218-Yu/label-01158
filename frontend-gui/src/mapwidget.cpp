#include "mapwidget.h"
#include <QPainter>
#include <QPainterPath>
#include <QMouseEvent>
#include <cmath>

MapWidget::MapWidget(QWidget *parent) : QWidget(parent) {
    setMinimumSize(400, 300);
    setMouseTracking(true);
}

void MapWidget::setGraph(CampusGraph *graph) {
    graph_ = graph;
    calculateTransform();
    update();
}

void MapWidget::setCurrentPath(const std::vector<int> &path) {
    currentPath_ = path;
    update();
}

void MapWidget::setSelectedSpot(int spotId) {
    selectedSpotId_ = spotId;
    update();
}

void MapWidget::clearPath() {
    currentPath_.clear();
    update();
}

void MapWidget::calculateTransform() {
    if (!graph_ || graph_->getSpots().empty()) return;
    
    const auto &spots = graph_->getSpots();
    minX_ = maxX_ = spots[0].x;
    minY_ = maxY_ = spots[0].y;
    
    for (const auto &spot : spots) {
        minX_ = std::min(minX_, spot.x);
        maxX_ = std::max(maxX_, spot.x);
        minY_ = std::min(minY_, spot.y);
        maxY_ = std::max(maxY_, spot.y);
    }
    
    double padding = 60;
    double scaleX = (width() - padding * 2) / (maxX_ - minX_ + 1);
    double scaleY = (height() - padding * 2) / (maxY_ - minY_ + 1);
    scale_ = std::min(scaleX, scaleY);
    
    offsetX_ = (width() - (maxX_ - minX_) * scale_) / 2 - minX_ * scale_;
    offsetY_ = (height() - (maxY_ - minY_) * scale_) / 2 - minY_ * scale_;
}

QPointF MapWidget::getSpotPosition(const Spot &spot) const {
    return QPointF(spot.x * scale_ + offsetX_, spot.y * scale_ + offsetY_);
}

QColor MapWidget::getSpotColor(const Spot &spot) const {
    if (spot.code == "TSG") return QColor(99, 102, 241);      // 图书馆 - 紫色
    if (spot.code.find("JX") != std::string::npos || spot.code == "HDG") 
        return QColor(59, 130, 246);                           // 教学楼 - 蓝色
    if (spot.code.find("CC") != std::string::npos || spot.code.find("TC") != std::string::npos || spot.code == "ZQTG")
        return QColor(34, 197, 94);                            // 体育场 - 绿色
    if (spot.code == "XZL") return QColor(139, 92, 246);      // 行政楼 - 紫色
    if (spot.code == "GJSY") return QColor(236, 72, 153);     // 实验室 - 粉色
    if (spot.code == "ZSJC") return QColor(245, 158, 11);     // 剧场 - 橙色
    return QColor(100, 116, 139);                              // 默认 - 灰色
}

void MapWidget::paintEvent(QPaintEvent *event) {
    Q_UNUSED(event);
    
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);
    
    // 背景
    painter.fillRect(rect(), QColor(26, 35, 50));
    
    if (!graph_) return;
    
    // 绘制草地区域
    painter.setBrush(QColor(30, 58, 47));
    painter.setPen(Qt::NoPen);
    painter.drawEllipse(QPointF(width() * 0.3, height() * 0.7), 80, 50);
    painter.drawEllipse(QPointF(width() * 0.7, height() * 0.3), 100, 60);
    
    // 绘制水域
    painter.setBrush(QColor(30, 58, 95));
    const Spot *riverSpot = graph_->getSpotByCode("BCH");
    if (riverSpot) {
        QPointF rp = getSpotPosition(*riverSpot);
        painter.drawEllipse(rp + QPointF(0, 20), 60, 30);
    }
    
    // 绘制道路
    QPen roadPen(QColor(61, 74, 92), 6, Qt::SolidLine, Qt::RoundCap);
    painter.setPen(roadPen);
    
    auto edges = graph_->getEdges();
    for (const auto &edge : edges) {
        const Spot *from = graph_->getSpotById(edge.from);
        const Spot *to = graph_->getSpotById(edge.to);
        if (from && to) {
            QPointF p1 = getSpotPosition(*from);
            QPointF p2 = getSpotPosition(*to);
            painter.drawLine(p1, p2);
        }
    }
    
    // 道路中线
    QPen dashPen(QColor(74, 85, 104), 2, Qt::DashLine);
    painter.setPen(dashPen);
    for (const auto &edge : edges) {
        const Spot *from = graph_->getSpotById(edge.from);
        const Spot *to = graph_->getSpotById(edge.to);
        if (from && to) {
            QPointF p1 = getSpotPosition(*from);
            QPointF p2 = getSpotPosition(*to);
            painter.drawLine(p1, p2);
        }
    }
    
    // 绘制路径
    if (currentPath_.size() > 1) {
        // 路径光晕
        QPen glowPen(QColor(245, 158, 11, 80), 14, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
        painter.setPen(glowPen);
        
        QPainterPath pathLine;
        for (size_t i = 0; i < currentPath_.size(); ++i) {
            const Spot *spot = graph_->getSpotById(currentPath_[i]);
            if (spot) {
                QPointF p = getSpotPosition(*spot);
                if (i == 0) pathLine.moveTo(p);
                else pathLine.lineTo(p);
            }
        }
        painter.drawPath(pathLine);
        
        // 路径主线
        QPen pathPen(QColor(245, 158, 11), 4, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
        painter.setPen(pathPen);
        painter.drawPath(pathLine);
        
        // 绘制箭头
        painter.setBrush(QColor(245, 158, 11));
        for (size_t i = 0; i < currentPath_.size() - 1; ++i) {
            const Spot *s1 = graph_->getSpotById(currentPath_[i]);
            const Spot *s2 = graph_->getSpotById(currentPath_[i + 1]);
            if (s1 && s2) {
                QPointF p1 = getSpotPosition(*s1);
                QPointF p2 = getSpotPosition(*s2);
                QPointF mid = (p1 + p2) / 2;
                double angle = std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
                
                painter.save();
                painter.translate(mid);
                painter.rotate(angle * 180 / M_PI);
                QPolygonF arrow;
                arrow << QPointF(8, 0) << QPointF(-4, -5) << QPointF(-4, 5);
                painter.drawPolygon(arrow);
                painter.restore();
            }
        }
    }

    // 绘制景点
    const auto &spots = graph_->getSpots();
    for (const auto &spot : spots) {
        QPointF p = getSpotPosition(spot);
        bool isSelected = (spot.id == selectedSpotId_);
        bool isInPath = std::find(currentPath_.begin(), currentPath_.end(), spot.id) != currentPath_.end();
        
        // 建筑阴影
        painter.setPen(Qt::NoPen);
        painter.setBrush(QColor(0, 0, 0, 80));
        painter.drawRoundedRect(QRectF(p.x() - 18, p.y() - 10, 36, 24), 4, 4);
        
        // 建筑主体
        painter.setBrush(getSpotColor(spot));
        painter.drawRoundedRect(QRectF(p.x() - 16, p.y() - 12, 32, 20), 3, 3);
        
        // 建筑高光
        painter.setBrush(QColor(255, 255, 255, 50));
        painter.drawRoundedRect(QRectF(p.x() - 14, p.y() - 10, 28, 8), 2, 2);
        
        // 选中/路径标记
        if (isSelected || isInPath) {
            QPen highlightPen(isInPath ? QColor(245, 158, 11) : QColor(59, 130, 246), 3);
            painter.setPen(highlightPen);
            painter.setBrush(Qt::NoBrush);
            painter.drawEllipse(p, 24, 24);
        }
        
        // 标签背景
        QFont font = painter.font();
        font.setPointSize(9);
        painter.setFont(font);
        QFontMetrics fm(font);
        int textWidth = fm.horizontalAdvance(QString::fromStdString(spot.name));
        
        painter.setPen(Qt::NoPen);
        painter.setBrush(QColor(0, 0, 0, 180));
        painter.drawRoundedRect(QRectF(p.x() - textWidth / 2 - 4, p.y() + 14, textWidth + 8, 16), 3, 3);
        
        // 标签文字
        painter.setPen(Qt::white);
        painter.drawText(QRectF(p.x() - textWidth / 2, p.y() + 14, textWidth, 16),
                        Qt::AlignCenter, QString::fromStdString(spot.name));
    }
    
    // 指南针 - 精美设计
    painter.save();
    painter.translate(width() - 45, 45);
    
    // 外圈
    painter.setPen(QPen(QColor(100, 116, 139), 2));
    painter.setBrush(QColor(30, 41, 59, 200));
    painter.drawEllipse(QPointF(0, 0), 28, 28);
    
    // 内圈
    painter.setPen(Qt::NoPen);
    painter.setBrush(QColor(51, 65, 85));
    painter.drawEllipse(QPointF(0, 0), 22, 22);
    
    // 刻度线
    painter.setPen(QPen(QColor(148, 163, 184), 1));
    for (int i = 0; i < 8; ++i) {
        painter.save();
        painter.rotate(i * 45);
        painter.drawLine(QPointF(0, -18), QPointF(0, -22));
        painter.restore();
    }
    
    // 北指针（红色）
    painter.setPen(Qt::NoPen);
    painter.setBrush(QColor(239, 68, 68));
    QPolygonF northArrow;
    northArrow << QPointF(0, -16) << QPointF(-4, 0) << QPointF(0, -4) << QPointF(4, 0);
    painter.drawPolygon(northArrow);
    
    // 南指针（白色）
    painter.setBrush(QColor(226, 232, 240));
    QPolygonF southArrow;
    southArrow << QPointF(0, 16) << QPointF(-4, 0) << QPointF(0, 4) << QPointF(4, 0);
    painter.drawPolygon(southArrow);
    
    // 中心点
    painter.setBrush(QColor(251, 191, 36));
    painter.drawEllipse(QPointF(0, 0), 3, 3);
    
    // N 标记
    painter.setPen(QColor(239, 68, 68));
    QFont nFont = painter.font();
    nFont.setBold(true);
    nFont.setPointSize(8);
    painter.setFont(nFont);
    painter.drawText(QRectF(-6, -28, 12, 10), Qt::AlignCenter, "N");
    
    painter.restore();
    
    // 比例尺
    painter.setPen(Qt::NoPen);
    painter.setBrush(QColor(74, 85, 104));
    painter.drawRect(20, height() - 30, 60, 4);
    
    painter.setPen(QColor(156, 163, 175));
    QFont scaleFont = painter.font();
    scaleFont.setPointSize(8);
    painter.setFont(scaleFont);
    painter.drawText(QRectF(20, height() - 48, 60, 16), Qt::AlignCenter, "100m");
}

void MapWidget::mousePressEvent(QMouseEvent *event) {
    if (!graph_) return;
    
    QPointF clickPos = event->position();
    
    for (const auto &spot : graph_->getSpots()) {
        QPointF spotPos = getSpotPosition(spot);
        double dist = std::sqrt(std::pow(clickPos.x() - spotPos.x(), 2) + 
                               std::pow(clickPos.y() - spotPos.y(), 2));
        if (dist < 25) {
            emit spotClicked(spot.id);
            return;
        }
    }
}

void MapWidget::resizeEvent(QResizeEvent *event) {
    Q_UNUSED(event);
    calculateTransform();
}
