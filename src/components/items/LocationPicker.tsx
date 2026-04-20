import { useState, useEffect } from 'react';
import { ChevronRight, ChevronDown, MapPin } from 'lucide-react';
import { useLocationStore } from '../../stores/useLocationStore';
import type { LocationTreeNode } from '../../types/location';

interface LocationPickerProps {
  value: string;
  onChange: (id: string) => void;
}

export default function LocationPicker({ value, onChange }: LocationPickerProps) {
  const { locationTree, locations, fetchLocations } = useLocationStore();
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (locations.length === 0) fetchLocations();
  }, [locations.length, fetchLocations]);

  const selectedLocation = locations.find((l) => l.id === value);

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="w-full flex items-center gap-2 px-3 py-2.5 bg-white border border-border rounded-[10px] text-sm text-left hover:border-gray-300 transition-colors"
      >
        <MapPin className="w-4 h-4 text-gray-400 shrink-0" />
        <span className={selectedLocation ? 'text-gray-800' : 'text-gray-400'}>
          {selectedLocation ? selectedLocation.full_path.replace(/\//g, ' > ') : '选择存放位置'}
        </span>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-border rounded-[12px] shadow-lg z-50 max-h-64 overflow-y-auto">
            <button
              type="button"
              onClick={() => { onChange(''); setOpen(false); }}
              className="w-full px-3 py-2 text-left text-sm text-gray-400 hover:bg-gray-50"
            >
              不选择位置
            </button>
            {locationTree.map((node) => (
              <TreeNode
                key={node.id}
                node={node}
                selectedId={value}
                onSelect={(id) => { onChange(id); setOpen(false); }}
              />
            ))}
            {locationTree.length === 0 && (
              <p className="px-3 py-4 text-sm text-gray-400 text-center">
                暂无位置，请先在"位置管理"中添加
              </p>
            )}
          </div>
        </>
      )}
    </div>
  );
}

function TreeNode({
  node, selectedId, onSelect, depth = 0,
}: {
  node: LocationTreeNode;
  selectedId: string;
  onSelect: (id: string) => void;
  depth?: number;
}) {
  const [expanded, setExpanded] = useState(true);
  const hasChildren = node.children.length > 0;

  return (
    <div>
      <button
        type="button"
        onClick={() => {
          if (hasChildren) setExpanded(!expanded);
          onSelect(node.id);
        }}
        className={`w-full flex items-center gap-1.5 px-3 py-2 text-sm text-left hover:bg-gray-50 ${
          selectedId === node.id ? 'bg-primary/5 text-primary' : 'text-gray-700'
        }`}
        style={{ paddingLeft: `${12 + depth * 20}px` }}
      >
        {hasChildren ? (
          expanded ? <ChevronDown className="w-3.5 h-3.5 text-gray-400" /> : <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
        ) : (
          <span className="w-3.5" />
        )}
        {node.name}
      </button>
      {expanded &&
        node.children.map((child) => (
          <TreeNode key={child.id} node={child} selectedId={selectedId} onSelect={onSelect} depth={depth + 1} />
        ))}
    </div>
  );
}
