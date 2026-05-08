#include "mainwindow.h"
#include "mapwidget.h"
#include "campus_data.h"
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QGroupBox>
#include <QSplitter>
#include <QScrollArea>
#include <QMessageBox>
#include <QTabWidget>
#include <QGridLayout>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    setWindowTitle("安徽理工大学校园导航系统");
    setMinimumSize(1200, 700);
    
    loadData();
    setupUI();
    
    // 设置样式
    setStyleSheet(R"(
        QMainWindow { background-color: #1f2937; }
        QGroupBox { 
            color: #f3f4f6; 
            font-weight: bold;
            border: 1px solid #374151;
            border-radius: 6px;
            margin-top: 12px;
            padding-top: 10px;
        }
        QGroupBox::title {
            subcontrol-origin: margin;
            left: 10px;
            padding: 0 5px;
        }
        QLabel { color: #d1d5db; }
        QLineEdit, QComboBox, QTextEdit, QListWidget {
            background-color: #374151;
            color: #f3f4f6;
            border: 1px solid #4b5563;
            border-radius: 4px;
            padding: 6px;
        }
        QComboBox {
            combobox-popup: 0;
        }
        QComboBox::drop-down {
            border: none;
            width: 20px;
        }
        QComboBox::down-arrow {
            image: url(down_arrow.png);
            width: 12px;
            height: 12px;
        }
        QComboBox QAbstractItemView {
            background-color: #374151;
            color: #f3f4f6;
            selection-background-color: #3b82f6;
            selection-color: white;
            border: 1px solid #4b5563;
        }
        QComboBox QAbstractItemView::item {
            min-height: 30px;
            padding: 4px;
        }
        QComboBox QAbstractItemView::item:hover {
            background-color: #4b5563;
        }
        QComboBox QAbstractItemView::item:selected {
            background-color: #3b82f6;
            color: white;
        }
        QLineEdit:focus, QComboBox:focus {
            border-color: #3b82f6;
        }
        QPushButton {
            background-color: #3b82f6;
            color: white;
            border: none;
            border-radius: 4px;
            padding: 8px 16px;
            font-weight: bold;
        }
        QPushButton:hover { background-color: #2563eb; }
        QPushButton:pressed { background-color: #1d4ed8; }
        QPushButton#swapBtn {
            background-color: #4b5563;
            border-radius: 18px;
            padding: 8px;
        }
        QPushButton#swapBtn:hover { background-color: #6b7280; }
        QPushButton#multiPathBtn {
            background-color: #10b981;
        }
        QPushButton#multiPathBtn:hover { background-color: #059669; }
        QListWidget::item {
            padding: 8px;
            border-bottom: 1px solid #374151;
        }
        QListWidget::item:selected {
            background-color: #3b82f6;
        }
        QListWidget::item:hover {
            background-color: #4b5563;
        }
        QCheckBox { color: #d1d5db; spacing: 8px; padding: 6px; }
        QCheckBox::indicator {
            width: 18px; height: 18px;
            border: 2px solid #4b5563;
            border-radius: 4px;
            background-color: #374151;
        }
        QCheckBox::indicator:hover {
            border-color: #3b82f6;
        }
        QCheckBox::indicator:checked {
            background-color: #3b82f6;
            border-color: #3b82f6;
            image: url(none);
        }
        QCheckBox::indicator:checked {
            background-color: #3b82f6;
            border-color: #3b82f6;
        }
        QTabWidget::pane {
            border: 1px solid #374151;
            border-radius: 4px;
            background-color: #1f2937;
        }
        QTabBar::tab {
            background-color: #374151;
            color: #9ca3af;
            padding: 8px 16px;
            border-top-left-radius: 4px;
            border-top-right-radius: 4px;
        }
        QTabBar::tab:selected {
            background-color: #3b82f6;
            color: white;
        }
        QScrollArea { border: none; background: transparent; }
    )");
}

void MainWindow::setupUI() {
    QWidget *centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);
    
    QHBoxLayout *mainLayout = new QHBoxLayout(centralWidget);
    mainLayout->setSpacing(10);
    mainLayout->setContentsMargins(10, 10, 10, 10);
    
    // 左侧面板 - 景点列表
    QWidget *leftPanel = new QWidget;
    leftPanel->setFixedWidth(280);
    QVBoxLayout *leftLayout = new QVBoxLayout(leftPanel);
    leftLayout->setSpacing(10);
    
    // 搜索框
    QGroupBox *searchGroup = new QGroupBox("搜索景点");
    QVBoxLayout *searchLayout = new QVBoxLayout(searchGroup);
    searchEdit_ = new QLineEdit;
    searchEdit_->setPlaceholderText("输入景点名称或代号...");
    searchLayout->addWidget(searchEdit_);
    leftLayout->addWidget(searchGroup);
    
    // 景点列表
    QGroupBox *listGroup = new QGroupBox("景点列表");
    QVBoxLayout *listLayout = new QVBoxLayout(listGroup);
    spotList_ = new QListWidget;
    for (const auto &spot : graph_.getSpots()) {
        QString text = QString::fromStdString(spot.name) + " (" + 
                      QString::fromStdString(spot.code) + ")";
        QListWidgetItem *item = new QListWidgetItem(text);
        item->setData(Qt::UserRole, spot.id);
        spotList_->addItem(item);
    }
    listLayout->addWidget(spotList_);
    leftLayout->addWidget(listGroup, 1);
    
    // 景点详情
    QGroupBox *infoGroup = new QGroupBox("景点详情");
    QVBoxLayout *infoLayout = new QVBoxLayout(infoGroup);
    spotInfoText_ = new QTextEdit;
    spotInfoText_->setReadOnly(true);
    spotInfoText_->setMaximumHeight(120);
    spotInfoText_->setPlaceholderText("点击景点查看详情...");
    infoLayout->addWidget(spotInfoText_);
    leftLayout->addWidget(infoGroup);
    
    mainLayout->addWidget(leftPanel);
    
    // 中间 - 地图
    mapWidget_ = new MapWidget;
    mapWidget_->setGraph(&graph_);
    mainLayout->addWidget(mapWidget_, 1);
    
    // 右侧面板 - 路径查询
    QWidget *rightPanel = new QWidget;
    rightPanel->setFixedWidth(300);
    QVBoxLayout *rightLayout = new QVBoxLayout(rightPanel);
    rightLayout->setSpacing(10);
    
    QTabWidget *tabWidget = new QTabWidget;
    
    // 两点路径标签页
    QWidget *pathTab = new QWidget;
    QVBoxLayout *pathLayout = new QVBoxLayout(pathTab);
    pathLayout->setSpacing(12);
    
    QLabel *startLabel = new QLabel("起点：");
    startCombo_ = new QComboBox;
    startCombo_->addItem("选择起点...", -1);
    for (const auto &spot : graph_.getSpots()) {
        startCombo_->addItem(QString::fromStdString(spot.name), spot.id);
    }
    pathLayout->addWidget(startLabel);
    pathLayout->addWidget(startCombo_);
    
    // 交换按钮
    swapBtn_ = new QPushButton("⇅");
    swapBtn_->setObjectName("swapBtn");
    swapBtn_->setFixedSize(36, 36);
    swapBtn_->setToolTip("交换起点和终点");
    QHBoxLayout *swapLayout = new QHBoxLayout;
    swapLayout->addStretch();
    swapLayout->addWidget(swapBtn_);
    swapLayout->addStretch();
    pathLayout->addLayout(swapLayout);
    
    QLabel *endLabel = new QLabel("终点：");
    endCombo_ = new QComboBox;
    endCombo_->addItem("选择终点...", -1);
    for (const auto &spot : graph_.getSpots()) {
        endCombo_->addItem(QString::fromStdString(spot.name), spot.id);
    }
    pathLayout->addWidget(endLabel);
    pathLayout->addWidget(endCombo_);
    
    findPathBtn_ = new QPushButton("🔍 查询最短路径");
    pathLayout->addWidget(findPathBtn_);
    
    pathResultText_ = new QTextEdit;
    pathResultText_->setReadOnly(true);
    pathResultText_->setPlaceholderText("查询结果将显示在这里...");
    pathLayout->addWidget(pathResultText_, 1);
    
    tabWidget->addTab(pathTab, "两点路径");

    // 多点路径标签页
    QWidget *multiTab = new QWidget;
    QVBoxLayout *multiLayout = new QVBoxLayout(multiTab);
    multiLayout->setSpacing(10);
    
    QLabel *multiLabel = new QLabel("选择要经过的景点（至少2个）：");
    multiLabel->setStyleSheet("font-weight: bold; margin-bottom: 5px;");
    multiLayout->addWidget(multiLabel);
    
    QScrollArea *scrollArea = new QScrollArea;
    scrollArea->setWidgetResizable(true);
    scrollArea->setStyleSheet("QScrollArea { background: #1f2937; border: 1px solid #374151; border-radius: 6px; }");
    
    multiSpotWidget_ = new QWidget;
    multiSpotWidget_->setStyleSheet("background: #1f2937;");
    QGridLayout *gridLayout = new QGridLayout(multiSpotWidget_);
    gridLayout->setSpacing(6);
    gridLayout->setContentsMargins(8, 8, 8, 8);
    
    int col = 0, row = 0;
    for (const auto &spot : graph_.getSpots()) {
        QCheckBox *cb = new QCheckBox(QString::fromStdString(spot.name));
        cb->setProperty("spotId", spot.id);
        cb->setStyleSheet(R"(
            QCheckBox {
                background: #374151;
                border: 1px solid #4b5563;
                border-radius: 4px;
                padding: 8px 10px;
                color: #e5e7eb;
            }
            QCheckBox:hover {
                border-color: #3b82f6;
                background: #3f4a5c;
            }
            QCheckBox:checked {
                background: rgba(59, 130, 246, 0.2);
                border-color: #3b82f6;
            }
            QCheckBox::indicator {
                width: 18px; height: 18px;
                border: 2px solid #6b7280;
                border-radius: 4px;
                background: #1f2937;
            }
            QCheckBox::indicator:hover {
                border-color: #3b82f6;
            }
            QCheckBox::indicator:checked {
                background: #3b82f6;
                border-color: #3b82f6;
                image: url(:/checkmark.svg);
            }
        )");
        connect(cb, &QCheckBox::toggled, this, &MainWindow::onCheckboxToggled);
        spotCheckboxes_.push_back(cb);
        gridLayout->addWidget(cb, row, col);
        col++;
        if (col >= 2) { col = 0; row++; }
    }
    
    scrollArea->setWidget(multiSpotWidget_);
    multiLayout->addWidget(scrollArea, 1);
    
    selectedCountLabel_ = new QLabel("已选择 0 个景点");
    selectedCountLabel_->setAlignment(Qt::AlignCenter);
    selectedCountLabel_->setStyleSheet("color: #9ca3af; padding: 8px; background: #374151; border-radius: 4px;");
    multiLayout->addWidget(selectedCountLabel_);
    
    findMultiPathBtn_ = new QPushButton("🗺️ 规划最佳路线");
    findMultiPathBtn_->setObjectName("multiPathBtn");
    findMultiPathBtn_->setStyleSheet(R"(
        QPushButton {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #10b981, stop:1 #059669);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 12px 16px;
            font-weight: bold;
            font-size: 13px;
        }
        QPushButton:hover {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #059669, stop:1 #047857);
        }
    )");
    multiLayout->addWidget(findMultiPathBtn_);
    
    tabWidget->addTab(multiTab, "多点路线");
    
    rightLayout->addWidget(tabWidget);
    mainLayout->addWidget(rightPanel);
    
    // 连接信号槽
    connect(searchEdit_, &QLineEdit::textChanged, this, &MainWindow::onSearchTextChanged);
    connect(spotList_, &QListWidget::itemClicked, this, &MainWindow::onSpotListClicked);
    connect(swapBtn_, &QPushButton::clicked, this, &MainWindow::onSwapPoints);
    connect(findPathBtn_, &QPushButton::clicked, this, &MainWindow::onFindPath);
    connect(findMultiPathBtn_, &QPushButton::clicked, this, &MainWindow::onFindMultiPath);
    connect(mapWidget_, &MapWidget::spotClicked, this, &MainWindow::onMapSpotClicked);
}

void MainWindow::loadData() {
    initCampusData(graph_);
}

MainWindow::~MainWindow() {}

void MainWindow::onSpotSelected(int index) {
    Q_UNUSED(index);
}

void MainWindow::onSpotListClicked(QListWidgetItem *item) {
    int spotId = item->data(Qt::UserRole).toInt();
    updateSpotInfo(spotId);
    mapWidget_->setSelectedSpot(spotId);
}

void MainWindow::onSearchTextChanged(const QString &text) {
    for (int i = 0; i < spotList_->count(); ++i) {
        QListWidgetItem *item = spotList_->item(i);
        bool match = text.isEmpty() || 
                    item->text().contains(text, Qt::CaseInsensitive);
        item->setHidden(!match);
    }
}

void MainWindow::onMapSpotClicked(int spotId) {
    updateSpotInfo(spotId);
    
    // 同步选中列表项
    for (int i = 0; i < spotList_->count(); ++i) {
        QListWidgetItem *item = spotList_->item(i);
        if (item->data(Qt::UserRole).toInt() == spotId) {
            spotList_->setCurrentItem(item);
            break;
        }
    }
}

void MainWindow::updateSpotInfo(int spotId) {
    const Spot *spot = graph_.getSpotById(spotId);
    if (spot) {
        QString info = QString("<b>%1</b> (%2)<br><br>%3")
            .arg(QString::fromStdString(spot->name))
            .arg(QString::fromStdString(spot->code))
            .arg(QString::fromStdString(spot->intro));
        spotInfoText_->setHtml(info);
        mapWidget_->setSelectedSpot(spotId);
    }
}

void MainWindow::onSwapPoints() {
    int startIdx = startCombo_->currentIndex();
    int endIdx = endCombo_->currentIndex();
    startCombo_->setCurrentIndex(endIdx);
    endCombo_->setCurrentIndex(startIdx);
}

void MainWindow::onFindPath() {
    int startId = startCombo_->currentData().toInt();
    int endId = endCombo_->currentData().toInt();
    
    if (startId < 0 || endId < 0) {
        showMessage("提示", "请选择起点和终点", true);
        return;
    }
    
    if (startId == endId) {
        showMessage("提示", "起点和终点不能相同", true);
        return;
    }
    
    PathResult result = graph_.dijkstra(startId, endId);
    showPathResult(result);
}

void MainWindow::onFindMultiPath() {
    std::vector<int> selectedIds;
    for (QCheckBox *cb : spotCheckboxes_) {
        if (cb->isChecked()) {
            selectedIds.push_back(cb->property("spotId").toInt());
        }
    }
    
    if (selectedIds.size() < 2) {
        showMessage("提示", "请至少选择2个景点", true);
        return;
    }
    
    PathResult result = graph_.multiSpotPath(selectedIds);
    showPathResult(result);
}

void MainWindow::onCheckboxToggled(bool checked) {
    Q_UNUSED(checked);
    int count = 0;
    for (QCheckBox *cb : spotCheckboxes_) {
        if (cb->isChecked()) count++;
    }
    selectedCountLabel_->setText(QString("已选择 %1 个景点").arg(count));
}

void MainWindow::showPathResult(const PathResult &result) {
    if (!result.found) {
        pathResultText_->setHtml("<span style='color: #ef4444;'>❌ 未找到可行路径</span>");
        mapWidget_->clearPath();
        return;
    }
    
    // 构建路径显示
    QStringList pathNames;
    for (int id : result.path) {
        const Spot *spot = graph_.getSpotById(id);
        if (spot) {
            pathNames << QString::fromStdString(spot->name);
        }
    }
    
    QString html = QString(
        "<div style='color: #22c55e; margin-bottom: 10px;'>✅ 路径查询成功</div>"
        "<div style='color: #d1d5db;'><b>路径：</b></div>"
        "<div style='color: #60a5fa; margin: 8px 0;'>%1</div>"
        "<div style='color: #d1d5db;'><b>总距离：</b>"
        "<span style='color: #10b981; font-size: 16px;'>%2 米</span></div>"
    ).arg(pathNames.join(" → ")).arg(result.totalDistance);
    
    pathResultText_->setHtml(html);
    mapWidget_->setCurrentPath(result.path);
}

void MainWindow::showMessage(const QString &title, const QString &message, bool isError) {
    if (isError) {
        QMessageBox::warning(this, title, message);
    } else {
        QMessageBox::information(this, title, message);
    }
}
