#pragma once

#include <QMainWindow>
#include <QComboBox>
#include <QListWidget>
#include <QTextEdit>
#include <QPushButton>
#include <QLabel>
#include <QCheckBox>
#include <QLineEdit>
#include "graph.h"

class MapWidget;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onSpotSelected(int index);
    void onSpotListClicked(QListWidgetItem *item);
    void onFindPath();
    void onSwapPoints();
    void onFindMultiPath();
    void onSearchTextChanged(const QString &text);
    void onMapSpotClicked(int spotId);
    void onCheckboxToggled(bool checked);

private:
    void setupUI();
    void loadData();
    void updateSpotInfo(int spotId);
    void showPathResult(const PathResult &result);
    void showMessage(const QString &title, const QString &message, bool isError = false);

    CampusGraph graph_;
    MapWidget *mapWidget_;
    
    // 左侧面板
    QLineEdit *searchEdit_;
    QListWidget *spotList_;
    QTextEdit *spotInfoText_;
    
    // 右侧面板
    QComboBox *startCombo_;
    QComboBox *endCombo_;
    QPushButton *swapBtn_;
    QPushButton *findPathBtn_;
    QTextEdit *pathResultText_;
    
    // 多点路径
    QWidget *multiSpotWidget_;
    std::vector<QCheckBox*> spotCheckboxes_;
    QPushButton *findMultiPathBtn_;
    QLabel *selectedCountLabel_;
};
